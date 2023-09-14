require 'faraday'
require 'json'

class ShopifyAdapter

    def initialize
        @base_url = ("https://bitsila-test.myshopify.com/admin/api/2023-07/")
        @headers = {
            "X-Shopify-Access-Token" => "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",
            "Content-Type" => "application/json"
            }
        @base_url2 = ("https://biz.test.bitsila.com/api/bitsila/")
            # 'bitsila-api-key' => '9$9$BITbUYvgbUW1XALw4I6UOzRn7qpJQQDeb5aILKds4FApkCqnJVbKILkq3c7yBZCCt0GSILA$9$9',
            # 'bitsila-client-token' => 'U2FsdGVkX1/6AnLqAHB7DCATeoJ+yEwLd7gAWs1B28U=',
        @headers2 = {
        
            'bitsila-api-key' => '9$9$BITiZjyCzpLt4iFc1tyeznf3PEeF9Ti4sKudoCZ1BgRBL8OjVr0H9OsVdrytwNhoLNXSILA$9$9',
            'bitsila-client-token' => 'U2FsdGVkX1+xka0W/BHjVYki3TFYtPLcetdXwj/1GH0=',
            'Content-Type' => 'application/json'
            }
    
        @conn = Faraday.new(url: @base_url, headers: @headers)
        @conn2 = Faraday.new(url: @base_url2, headers: @headers2)
    end 

    def update_catalog
        ## // Call shopify get catalog API //
        collection_ids=[]
        ## // call custom_collection api //
        response_for_custom = @conn.get("custom_collections.json")
        data_for_custom  = JSON.parse(response_for_custom.body)
        data_for_custom ["custom_collections"].each do |custom_collections|
            collection_ids.push(custom_collections["id"])
        end
        ## // call smart_collection api //
        response_for_smart = @conn.get("smart_collections.json")
        data_for_smart  = JSON.parse(response_for_smart.body)
        if !(data_for_smart).empty?
            data_for_smart["smart_collections"].each do |smart_collections|
                collection_ids.push(smart_collections["id"])
            end
        end
        payload = { "catalog" => {}}
        payload["catalog"]["categories"] = []
       
        
        
        collection_ids.each do |id|
            category={}
            response_for_collections = @conn.get("collections/#{id}.json")
            data_for_collections  = JSON.parse(response_for_collections.body)
             
            category["ref_id"] =  data_for_collections["collection"]["id"]
            category["name"] =  data_for_collections["collection"]["title"]
            category["description"] =  data_for_collections["collection"]["body_html"]
            category["status"] =  "active"
            category["groups"] = []
                response_collects_of_products = @conn.get("collections/#{id}/products.json")
                data_collects_of_products  = JSON.parse(response_collects_of_products.body)
                ## // looping collection_id_products products api //     
                data_collects_of_products["products"].each do |product|
                group = {}
                group["ref_id"] =  product["id"].to_s
                group["category_ref_id"] =  data_for_collections["collection"]["id"]
                group["name"] =  product["title"]
                group["description"] =  product["body_html"]
                group["image_urls"] =   product["images"].empty? ? "" : product["images"][0]["src"]
                group["status"] =  product["status"] == "draft" ? "inactive" : product["status"]
                group["items"] = []
                    response_of_product = @conn.get("products/#{product["id"]}.json") 
                    data_of_product  = JSON.parse(response_of_product.body)
                    
                        data_of_product["product"]["variants"].each do |x|
                        items  = {}
                        items["ref_id"] =  x["id"].to_s
                        items["name"] =  x["title"]
                        items["description"] =  ""
                        items["display_order"] =  x["position"]
                        items["status"] =  product["status"] == "draft" ? "inactive" : product["status"]
                        items["inventory"] =  x["inventory_quantity"] <=0 ? false : true
                        items["image_urls"] =  x["image_id"].nil? ? ""  : product["images"].find { |image| image["id"] == x["image_id"] }["src"]
                        items["price"] =  x["price"]
                        items["item_type"] =  product["product_type"] == "" ? "not_applicable" : product["product_type"]
                        items["has_cess_tax"] =  false
                        items["cess_tax"] =  "5.0"
                        items["tax_ids"] =  ["0"]
                        items["order_types"] = nil
                        items["best_seller"] =  data_for_collections["collection"]["sort_order"] == "best-selling" ? true : false
                        # items["product_category"] =  data_for_collections["collection"]["title"]
                        items["tags"] =  product["tags"]

                            group["items"].push(items)
                        end
                    
                    category["groups"].push(group)
                end
            payload["catalog"]["categories"].push(category)
        end
        payload["catalog"]["taxes"] = [{
            "ref_id": "0",
            "name": "0",
            "tax": 0,
            "breakup": {
                "cgst": 0,
                "igst": 0,
                "sgst": 0
            }
        }]
        payload["catalog"]["variant_groups"] = nil
        payload["catalog"]["offers"] = nil
        payload["catalog"]["callback_url"] = "https://webhook.site/e9d16aad-68ed-4259-8f78-4ecf7704df13"
        puts payload 
        # response2 = @conn2.post("update_catalog.json", payload.to_json )
        # data2 = JSON.parse(response2.body)
        # puts data2
    end
              

    def update_inventory
        response = @conn.get("products.json")
        data = JSON.parse(response.body)
        payload = {}
            payload["outlet_id"] = "1"
            payload["items"] = [] 
            data["products"].each do |product|
                product["variants"].each do |x|
                    item = {}
                    item["ref_id"] = x["id"]
                    item["price"] = x["price"]
                    item["online_price"] = x["price"]
                    item["store_price"] = x["price"]
                    item["b2b_online_price"] = x["price"]
                    item["b2b_store_price"] = x["price"]
                    item["in_stock"] = x["inventory_quantity"] == 0 ? false : true
                    item["stock_qty"] = x["inventory_quantity"]
                    item["status"] = x["status"]

                    payload["items"].push(item)
                end
            end
        response2 = @conn2.post("update_inventory.json", payload.to_json )
        data2 = JSON.parse(response2.body)
        puts data2
    end

    def update_store_catalog
        ## //  Call shopify get catalog API //
        # response_inventory = @conn.get("")
        response = @conn.get("products.json")
            data = JSON.parse(response.body)
            payload = {}
            ## // Transform the payload to Bitsila update_store_catalog API payload //
            payload["store"] = {}
            payload["store"]["outlet_id"] = "1"
            payload["store"]["name"] = "lihith store"
            payload["store"]["contact_name"]  = "lihith"
            payload["store"]["mobile_number"] = "9731311444"
               
            payload["items"] = []
            data["products"].each do |product|
                product["variants"].each do |i|
                    item = {} 
                    item["ref_id"] = i["id"].to_s
                    item["price"] = i["price"]
                    item["online_price"] = i["price"]
                    item["store_price"] = i["price"]
                    item["in_stock"] = i["inventory_quantity"] <= 0 ? false : true 
                    item["stock_qty"] = i["inventory_quantity"]
                    item["status"] = "active"
                        payload["items"].push(item)
                end
            end 
            ## //  Make a post call to Bitsila API //
            response2 = @conn2.post("update_store_catalog.json", payload.to_json )
            data2 = JSON.parse(response2.body)
            puts JSON.pretty_generate(data2)
        
    end

    def order_push
      order='{
        "data": {
          "order_relay_data": {
            "customer": {
              "name": "chris evans",
              "phone_number": "5555555555",
              "country_code": "91",
              "email": "ce@gmail.com",
              "gender": "male",
              "age": 0,
              "address": {
                "address_1": "",
                "address_2": "",
                "locality": null,
                "landmark": "",
                "pincode": "560102",
                "city": "Bengaluru",
                "country": "India",
                "instructions": "1, 2, 3, HSR Layout HSR Layout, Bengaluru, Karnataka, India",
                "latitude": 12.9121181,
                "longitude": 77.6445548
              }
            },
            "order": {
              "outlet_name": "lihith store",
              "outlet_ref_id": "1",
              "order_no": "2875-1003-1062",
              "order_ref_no": "",
              "ordered_on": 1694674944,
              "delivery_on": null,
              "order_type": "pos",
              "fulfilment_type": "delivery",
              "logistics_type": "self",
              "item_level_charges": 0,
              "item_level_taxes": 0,
              "order_level_charges": 0,
              "order_level_taxes": 44.3,
              "order_offer_amount": 0,
              "item_offer_amount": 0,
              "order_offer_ref_id": null,
              "extra_info": {
                "no_of_persons": 0,
                "table_no": 0
              },
              "sub_total": 885.95,
              "total_charges": 10,
              "total_offer_amount": 0,
              "total_taxes": 44.3,
              "total_amount": 940.25,
              "prep_time": 15,
              "notes": ""
            },
            "order_items": [
              {
                "ref_id": "46483319947573",
                "name": "Default Title 1.0 pc",
                "price": 885.95,
                "quantity": 1,
                "offer_amount": 0,
                "sub_total": 0,
                "charges": 0,
                "tax": 5,
                "total_amount": 885.95,
                "notes": "",
                "charges_breakup": [
                  {
                    "packaging_charges": 0,
                    "delivery_charges": 10
                  }
                ],
                "tax_breakup": [],
                "variation_name": "",
                "variation_id": "",
                "customization": []
              }
            ],
            "offers": [],
            "payment": {
              "amount_paid": 940.25,
              "amount_balance": 940.25,
              "mode": "cash",
              "status": "success"
            }
          }
        },
        "help": null,
        "alerts": null
      }'
    
        response = JSON.parse(order)
    
        a = ((response["data"]["order_relay_data"]["order"]["total_taxes"]) / (response["data"]["order_relay_data"]["order"]["sub_total"])).round(2) /2
    
        payload = { "order" => {} }
        payload["order"]["line_items"] = []
    
            response["data"]["order_relay_data"]["order_items"].each do |x|
                item = {}
                item["variant_id"] = x["ref_id"]
                item["quantity"] = x["quantity"]
                payload["order"]["line_items"].push(item)
            end
    
        payload["order"]["customer"]= {}
        payload["order"]["customer"]["first_name"] = response["data"]["order_relay_data"]["customer"]["name"].split(" ")[0]
        payload["order"]["customer"]["last_name"] = response["data"]["order_relay_data"]["customer"]["name"].split(" ")[1]
        payload["order"]["customer"]["email"] = response["data"]["order_relay_data"]["customer"]["email"]

    
        payload["order"]["billing_address"]= {}
        payload["order"]["billing_address"]["first_name"] = response["data"]["order_relay_data"]["customer"]["name"].split(" ")[0]
        payload["order"]["billing_address"]["last_name"] = response["data"]["order_relay_data"]["customer"]["name"].split(" ")[1]
        payload["order"]["billing_address"]["address1"] = response["data"]["order_relay_data"]["customer"]["address"]["instructions"]
        payload["order"]["billing_address"]["phone"] = response["data"]["order_relay_data"]["customer"]["phone_number"]
        payload["order"]["billing_address"]["city"] = response["data"]["order_relay_data"]["customer"]["address"]["city"]
        payload["order"]["billing_address"]["country"] = response["data"]["order_relay_data"]["customer"]["address"]["country"]
        payload["order"]["billing_address"]["zip"] = response["data"]["order_relay_data"]["customer"]["address"]["pincode"]
    
        payload["order"]["shipping_address"] = {}
        payload["order"]["shipping_address"]["first_name"] = response["data"]["order_relay_data"]["customer"]["name"].split(" ")[0]
        payload["order"]["shipping_address"]["last_name"] = response["data"]["order_relay_data"]["customer"]["name"].split(" ")[1]
        payload["order"]["shipping_address"]["address1"] = response["data"]["order_relay_data"]["customer"]["address"]["instructions"]
        payload["order"]["shipping_address"]["phone"] = response["data"]["order_relay_data"]["customer"]["phone_number"]
        payload["order"]["shipping_address"]["city"] = response["data"]["order_relay_data"]["customer"]["address"]["city"]
        payload["order"]["shipping_address"]["country"] = response["data"]["order_relay_data"]["customer"]["address"]["country"]
        payload["order"]["shipping_address"]["zip"] = response["data"]["order_relay_data"]["customer"]["address"]["pincode"]
    
        payload["order"]["email"] = response["data"]["order_relay_data"]["customer"]["email"]
    
        payload["order"]["transactions"] = []
            transaction = {}
            transaction["kind"] = response["data"]["order_relay_data"]["payment"]["mode"]
            transaction["status"] = response["data"]["order_relay_data"]["payment"]["status"]
            transaction["amount"] = response["data"]["order_relay_data"]["payment"]["amount_paid"]
            payload["order"]["transactions"].push(transaction)
    
        payload["order"]["tax_lines"] = []
        tax1 = {}
        tax1["price"] =  ((response["data"]["order_relay_data"]["order"]["sub_total"]) * a).round(2)
        tax1["rate"] = a
        tax1["title"] = "state tax"
        tax2 = {}
        tax2["price"] = ((response["data"]["order_relay_data"]["order"]["sub_total"]) * a).round(2)
        tax2["rate"] = a
        tax2["title"] = "country tax"
        payload["order"]["tax_lines"].push(tax1)
        payload["order"]["tax_lines"].push(tax2)
    
        payload["order"]["total_tax"] = response["data"]["order_relay_data"]["order"]["total_taxes"]
    
      
        # puts JSON.pretty_generate(payload)
    
        responseO = @conn.post("orders.json", payload.to_json , @headers )
        dataO = JSON.parse(responseO.body)
        puts JSON.pretty_generate(dataO)
    
    end


    def order_status_push

      responseO = @conn.get("orders.json", @headers )
      dataO = JSON.parse(responseO.body)
      id = dataO["orders"][0]["id"]
      payload={}
      responseOr = @conn.post("orders/#{id}/cancel.json", payload.to_json , @headers )
      dataOr = JSON.parse(responseO.body)
      puts JSON.pretty_generate(dataOr)

      
    end



  def order_status_update

    payload={}
    payload["outlet_id"] = "1"
    payload["order_number"] = "2875-1003-1066" 

    response5 = @conn.get("orders.json?status=any", @headers )
    data5 = JSON.parse(response5.body)

    data5["orders"].each do |i|
      if i["source_identifier"] == payload["order_number"]
        a = i["source_identifier"]
        b = i["id"]
        puts b

        response = @conn.get("orders/#{b}.json", @headers )
        data = JSON.parse(response.body)
        if (data["order"]["fulfillments"]) == []
          puts "fulfill the items before order_status_update"
        else
          fullfillment_id = JSON.pretty_generate(data["order"]["fulfillments"][-1]["id"])
          
          response1 = @conn.get("orders/#{b}/fulfillments/#{fullfillment_id}.json", @headers )
          data1 = JSON.parse(response1.body)
          # puts data1
          puts data1["fulfillment"]["shipment_status"]

          a ={
            "ready_for_pickup" => "order_picked",
            "out_for_delivery" => "out_for_delivery",
            "delivered" => "order_delivered",
            
          } 

          if !(data["order"]["cancelled_at"]).nil?
            payload["new_status"] = "order_canceled"
            payload["cancel_reason"] = data["order"]["cancel_reason"]
          elsif data1["fulfillment"]["shipment_status"] == nil
            list = ["order_accepted","order_in_kitchen","order_is_ready"]
            list.each do |i|
                payload["new_status"] = i
                response3 = @conn2.post("update_order_status.json", payload.to_json )
                data3 = JSON.parse(response3.body)
                puts data3         
            end
          elsif a.include? data1["fulfillment"]["shipment_status"] 
            payload["new_status"]  = a[data1["fulfillment"]["shipment_status"]]
            response3 = @conn2.post("update_order_status.json", payload.to_json )
            puts JSON.parse(response3.body)
          end 
        end
      end
    end

  end
    
    def rider_status_update
      response = @conn.get("orders/5724006547765.json", @headers )
      data = JSON.parse(response.body)
      fullfillment_id = JSON.pretty_generate(data["order"]["fulfillments"][1]["id"])
      
      response1 = @conn.get("orders/5724006547765/fulfillments/#{fullfillment_id}.json", @headers )
      data1 = JSON.parse(response1.body)
      # event_id = JSON.pretty_generate(data1["fulfillment_events"][-1]["id"])

      # response2 = @conn.get("orders/5724006547765/fulfillments/#{fullfillment_id}/events/#{event_id}.json", @headers )
      # data2 = JSON.parse(response2.body)

      a ={
        "confirmed" => "assigned",
        "ready_for_pickup" => "at_store",
        "in_transit" => "picked_up",
        "out_for_delivery" => "out_for_delivery",
        "delivered" => "order_delivered",
        "attempted_delivery" => "pending"
      }
      payload = {}
     
      payload["outlet_id"] = "1"
      payload["order_no"] = "2875-1003-10"
      # payload["rider_data"]={"name":"","phone_number":"","tracking_url":data2["fulfillment_event"]["tracking_url"]}
      # puts data1

      payload["remarks"] = ""
      puts data2["fulfillment_event"]["status"]
      puts payload
      if !(data["order"]["cancelled_at"]).nil?
        payload["status"] = "order_canceled"
        
      elsif a.include? data2["fulfillment_event"]["status"] 
        payload["status"]  = a[data2["fulfillment_event"]["status"]]
      else 
        payload["status"]  = "order_placed"
      end
      
      # payload = {"outlet_id":"1","order_number":"2875-1003-1037","new_status":"order_is_ready"}
      response3 = @conn2.post("update_rider_status.json", payload.to_json )
      data3 = JSON.parse(response3.body)
      puts data3


    end
    
    
end         

obj=ShopifyAdapter.new
# obj.order_status_push
# obj.order_push
# obj.update_catalog
# obj.update_inventory
# obj.update_store_catalog
obj.order_status_update
# obj.rider_status_update