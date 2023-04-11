from django.shortcuts import render

def specific_static(request):
    return render(request,'specific_static.html')
