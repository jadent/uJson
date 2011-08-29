uJson: An APEX class for working with JSON
==========================================
Thanks to Hurricane Irene there was nowhere to go on Saturday night.  
Thus i forced myself to do something productive and tackle something on my list.  
So I whipped this out in about 6 hours so please be kind with your comments & bugs.  

If you have any suggestions for improvements please lmk. Thanks and enjoy!

Why uJson?  
----------
* Very simple and easy to use JSON class
* Needed to reduce the number of script statments when processing JSON
* Hurricane Irene thwarted my saturday night plans


How to Use It
-------------
uJson stores all values as uJson objects and both the put & get methods 
return a uJson object. 


    // Create some JSON  
    uJson j = new uJson()  
        .put('name', 'ryan')  
        .put('isCool', false);  
    String myJson = j.toJson();


    // Retrieving Values
    //   You can use either the val property or method on a uJson object.
    //   Both return an Object so you will have to cast it
    String name1 = (String) j.get('name').val;
    String name2 = (String) j.val('name');

    // Parsing JSON
    j = new uJson('{"name": "Joe"}');
    String name3 = (String) j.val('name');