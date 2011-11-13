/**
 * Software License Agreement (BSD License)
 * 
 * Copyright (c) 2011, Ryan Hubbard (ryanmhubbard@gmail.com)
 * All rights reserved.
 *
 * @author Ryan Hubbard (ryanmhubbard@gmail.com)
 * @version 1.0
 *
 * uJson (Utility for JSON) is a APEX class for Salesforce.com. Its goal is to
 *   <li>Be very easy to use</li>
 *   <li>Use less script execution statments when parsing JSON
 *   <li>Be a temp solution before SF builds in native JSON support</li>
 *
 * uJson stores the data as key/val pairs. All values are uJson objects as well regardless
 * of their data types (primitive, array, object). This allows a very simple solution and works
 * well for nested JSON objects. The class is very easy to use and 
 *   
 * // Construct a blank uJson object and add values
 * uJson j = new uJson()
 *    .put('name', 'Ryan')
 *    .put('list', new Integer[]{1,2,3});
 * String myJson = j.toJson();
 * 
 * // 2 Ways to retrieve stored values
 * //   <li>get Method retrieves the key but returns a uJson Object, you use the "val" property to get the stored value</li>
 * //   <li>getVal method retrieves the value stored at the key</li>
 * String myName;
 *   myName = (String) j.get('name').val
 *   myName = (String) j.val('name');
 * 
 * // Start from JSON
 * uJson j = new uJson('{"name": "Ryan"}');
 * String myName = j.val('name');
 *
 */
global class uJson implements Iterator<uJson> {
    protected Map<String, uJson> obj;
    protected Object primitive;
    protected Object[] collection;
    
    protected Boolean isCollection = false;
    protected Boolean isPrimitive = false;
    protected Boolean isObject = false;
    protected Integer i;
    
    public String[] keys {
        get { 
            return isObject 
                ? new List<String>( obj.keySet() )
                : null;     
        }
    }
    
    global Boolean hasNext() {
        return i <= obj.keySet().size();
    }
    
    global uJson next() {
        return get( keys[i++] );  
    }
    
    
    public Object val {
        get{ 
            if ( isPrimitive )  return primitive;
            if ( isCollection ) return collection;
            return obj;         
        }
    }
   
    /**
     * Blank Constructor
     */
    public uJson() {
        isObject = true;
        obj = new Map<String, uJson>{};
    }
    
    /**
     * Parses the provided JSON into an uJson object
     *
     * @param JSON
     * @return a uJson object 
     */
    public uJson(String value) {
        if ( value == null ) {
            obj = new Map<String, uJson>{};
            return;
        }
        
        uJson.Tokenizer t = new uJson.Tokenizer(value);
        uJson j = t.parse();
        isObject = true;
        obj = j.obj;
    }
    
    /**
     * Primitive Data Type Constructor
     * @param value primitive data types (Blob,Boolean,....,String)
     */
    public uJson(Object value) {
        isPrimitive = true;
        primitive = value;
    }
    
    /**
     * List Constructor
     * @param value any collection
     */
    public uJson(Object[] value) {
        isCollection = true;
        collection = value;
        
    }

    /**
     * only for arrays
     */
    public uJson add(Object value) {
        if ( isCollection )
            collection.add(value);
        
        return this;
    }  
    
    public uJson add(String key) {
        return put(key, new uJson());
    }
    
    /**
     * Retreives the uJson for a key. Used mainly nested objects 
     * or handy for adding elements to an array
     *
     * @param key the key
     *
     * @return the uJson object
     */      
    public uJson get(String key) {                          
        return obj.get(key);
    }
        
    /**
     * Retreives the list for a key. Handy for grabbing a list directly
     *
     * @param key the key
     *
     * @return the list
     */     
    public Object[] getList(String key) {
        return (Object[]) obj.get(key).val;
    }
    
    /**
     * Adds a key/value pair to the JSON for primitive data types
     *
     * @param key the key
     * @param value the value
     *
     * @return the uJson object
     */
    public uJson put(String key, Object value) {
        obj.put(key, new uJson(value) );
        return this;   
    }
    
    /**
     * Adds a key/value pair to the JSON for lists
     *
     * @param key the key
     * @param value the value
     *
     * @return the uJson object
     */
    public uJson put(String key, Object[] value) {
        obj.put(key, new uJson(value));  
        return this;
    }
    
    public uJson put(String key, uJson value) {
        obj.put(key, value);
        return this;
    }
    /**
     * Converts the object to JSON
     *
     * @return the object converted to JSON
     */
    public String toJson() {
        
        if ( isPrimitive )
            return uJson.valueToJson(primitive);
        
        // Handle the Collection
        if ( isCollection ) {
            String txt = '[';
            for ( Object o : collection ) {
                if ( o instanceof uJson )
                    txt += ( (uJson) o).toJson() + ',';
                else
                    txt += uJson.valueToJson(o) + ','; 
            } 
                    
            return txt.substring(0, txt.length()-1) + ']';
        }
        
        // Handle the Object
        String txt = '{';
        for ( String key : obj.keySet() )
            txt += '"' + key + '": ' + obj.get(key).toJson() + ', ';
        return txt.length() == 1
            ? txt + '}'
            : txt.substring(0, txt.length()-2) + '}';
    }

    /**
     * Retreives the value for a key
     *
     * @param key the key
     *
     * @return the value
     */    
    public Object val(String key) {
        return obj.get(key).val;
    }
    
    /**
     * Converts an object to JSON for storing as a value
     * 
     * @param v the object to convert
     * @return the object converted to an JSON value
     */
    private static String valueToJson(Object v) {
        if ( v == null )  
            return 'null';
        if ( v instanceof String ) 
            return '"' + v + '"'; 
        if ( v instanceof Boolean  )
            return (Boolean) v ? 'true' : 'false';
        
        return String.valueOf(v);
    }
     
    /**
     * The uJson Exception object
     */
    public class TokenizerException extends Exception {}
   
   
//=============================================================================
// The Tokenizer Class
//=============================================================================    
    /**
     * The Tokenizer Class
     * Its function is to parse JSON strings
     */
    public class Tokenizer {
        private string txt;
        public Integer pointer = 0;
        
        /**
         * Constructor
         */
        public Tokenizer(String val) {
            txt = val;
        }
        
        /**
         * Get the current character that the pointer is at
         *
         * @return the current character
         */
        public String currentChar() {
            return txt.substring(pointer, pointer+1);
        }

        /**
         * Handles retrieving an Object from the JSON
         */
        private uJson getObject() { 
            Tokenizer t = new Tokenizer( txt.substring(pointer) );
            uJson j = t.parse();
            
            pointer += t.pointer;
            return j;

        }
        
        /**
         * Handles retrieving an array from the JSON
         */
        private Object getArray() {
            pointer++;
            Object[] c = new Object[]{};
            for(;;) {
                c.add( nextValue() );                
                if ( next(',') == null )
                    break;
            }
            if ( currentChar() != ']' )
                throw new uJson.TokenizerException('Invalid JSON while parsing array');
            
            pointer++;
            return c;
        }
        
        /**
         * Retreive the next string alue
         *
         * @return the string value
         */  
        private String getStringValue(Integer start) {  
            for (;;) {
                pointer = txt.indexOf('"', pointer+1);
                if ( pointer == -1 )
                    throw new uJson.TokenizerException('Unexpected end of JSON parsing string value');
                    
                String prev = txt.substring(pointer-1, pointer);
                if ( prev != '\\' )
                    break; 
            }
            String v = txt.substring(start, pointer++);
            return v.replace('\\"', '"');
        }        
        
        /**
         * Retreive the next non-string primitive value
         *
         * @return the non-string primitive value
         */        
        private Object getValue(Integer start) {
            Integer stop = nextCloser();
            if ( stop == null )
                throw new uJson.TokenizerException('Unexpected end of JSON while parsing value');
                
            String val = txt.substring(start, stop).trim().toLowerCase();
            system.debug('*** Non-String: "' + val + '"');
            if ( val == 'true' ) return true;
            if ( val == 'false' ) return false;
            if ( val == 'null' ) return null;
            
            // Handle Number
            if ( val.indexOf('.') >= 0 )
                return Double.valueOf(val);
            
            return Integer.valueOf(val);
            
        }
        
        /**
         *
         */
        public uJson parse() {
            if ( next('{') == null )
                throw new uJson.TokenizerException('JSON must start with a "{" character');


            uJson j = new uJson(); 
            for(;;) {
                // Get the key
                String key = nextKey();
                if ( key == null ) {
                    System.debug('*** Key not found');
                    break;
                }
                
                // Get the value
                next(':');
                Object val = nextValue();
                system.debug ('*** Val: ' +  val );
                if ( val == NULL )
                    j.put(key, val);
                else if ( val instanceof Object[] )
                    j.put(key, (Object[]) val );
                else if (val instanceof uJson )
                    j.put(key, (uJson) val);
                else
                    j.put(key, val);
                
                // Move to the next key/val pair
                if ( next(',') == null ) {
                    System.debug('*** No more Keys');
                    break;
                }            
            }
            if ( next('}') == null )
                throw new TokenizerException('JSON must end with a "}" character');
            
            return j;           
        }
        
        /**
         * Moves up to the next non-whitespace character (but does not consume it)
         * 
         * @return the current character it just moved to, NULL if we are out of characters
         */
        public String next() {
            for (;;) {
                if ( pointer >= txt.length() )
                    break;
                    
                String c = txt.substring(pointer, pointer+1);
                if ( c != ' ' && c != '\n' )
                    return c;
               
                pointer++;
            }
            
            return null;
        }
                        
        /**
         * Moves up to and consumes the the provided token. Since we are expecting this token
         * the function will return NULL if any other non-whitespace character is found
         * 
         * @return the current location or NULL if the character is not found first.
         *         if the token is not found the location is set to the unexpected token
         */
        public Integer next(String token) {
            for (;;) {
                if ( pointer >= txt.length() )
                    break;
                
                String c = txt.substring(pointer, ++pointer);   
                if ( token == c )
                    return pointer;
                if ( c != ' ' && c != '\n' ) {
                    pointer--;
                    return null;
                }
            }
            
            return null;
        }

       /**
        * Move up to the next closing character
        */
        private Integer nextCloser() {
            for(;;) {
                if ( pointer >= txt.length() )
                    break;
                    
                String c = txt.substring(pointer, ++pointer);   
                //System.debug('*** Testing: ' + c + ' at ' + (pointer-1));
                if ( c == ',' || c =='}' || c == ']' )
                    return --pointer;
               
            }
            return null;
        }
        
        /**
         * Retrieves the next key in the JSON
         *
         * @return the key name
         */
        public String nextKey() {
            // Get the start & stopping indexes of the key
            System.debug('*** Next Key Start: ' + pointer);
            Integer start = next('"');
            if ( start == null )
                return null;
            Integer stop = txt.indexOf('"', start);
            if ( stop == -1 )
                throw new uJson.TokenizerException('Unexpected end of JSON parsing key');
                
            // Extract the key
            String key = txt.substring(start, stop);
            if (! Pattern.matches('^[0-9a-zA-Z_]*$', key) )
                throw new uJson.TokenizerException('Invalid characters in key: ' + key);
            
            
            // Advance the point
            pointer = stop+1;

            return key;
        }
        
        /**
         * Retrieves the next value from the JSON
         *
         * @return the value which could be a primitive, List, or uJson (for nested objects)
         */
        public Object nextValue() {
            String c = next();
            System.debug('*** Starting Char: ' + c + ' at ' + pointer);
            if ( c == '"' )  return getStringValue(pointer+1);
            if ( c == '{' )  return getObject();
            if ( c == '[' )  return getArray();

            return getValue(pointer);
        }
        

                
    }
    
//=============================================================================
// Unit Testing
//=============================================================================
    public static testMethod void testJsonCreation() {
        String e; 
        
        uJson j = new uJson()
            .put('name', 'Ryan')
            .put('age', 33)
            .put('married', false)
            .put('num', new Integer[]{0,1,2})
            .put('d', 1.2)
            .put('e', e);
        
        String s = '{"d": 1.2, "num": [0,1,2], "e": null, "married": false, "age": 33, "name": "Ryan"}';
        System.assertEquals(j.toJson(), s);
    }
    
    public static testMethod void testParsing() {
        String n = '{"ga": true, "gb": "string"}';
        String s = '{"a":"Str", "b":true, "c": 10, "d":[0,1,2], "e": null, "f": 1.1, "g":' + n + '}';
        uJson j = new uJson(s); 
        
        // Test Primitives
        System.assertEquals( j.val('b'), true  );
        System.assertEquals( j.val('a'), 'Str' );
        System.assertEquals( j.val('c'), 10   );
        System.assertEquals( j.val('e'), null  );
        System.assertEquals( j.val('f'), 1.1      );
        System.assertEquals( j.get('g').val('gb'), 'string'  );
        
        // Test the list
        Object[] l = j.getList('d');
        System.assertEquals(3, l.size());
        System.assertEquals(0, l[0]);
        System.assertEquals(1, l[1]); 
        System.assertEquals(2, l[2]); 
        
        // Test convinience functions
        j.get('d').add(5);
        System.assertEquals(5, l[3]);
        
        System.assert( j.get('g').val instanceof Map<String, uJson> );
    }
    
    public static testMethod void testEmpty() {
        uJson j = new uJson('{}');
        System.assertEquals('{}', j.toJson());
        
        j = new uJson('{"key": {}}');
        System.assertEquals('{"key": {}}', j.toJson());
    }
    
    public static testMethod void testInvalid() {
        // Test JSON not starting with { 
        try {
            uJson j = new uJson('this is not JSON');
        } catch(Exception e) {
            System.assert( e.getMessage().contains('"{" character'));
        }


        // Test JSON not ending with }
        try {
            uJson j = new uJson('{');
        } catch(Exception e) {
            System.assert( e.getMessage().contains('must end with'));
        }   
        
        
        // Test unexcepted end of JSON
        try {
            uJson j = new uJson('{"test": true');
        } catch(Exception e) {
            System.assert( e.getMessage().contains('Unexpected end of JSON'));
        }
        
        
        // Test invalid key 
        try {
            uJson j = new uJson('{"test-": true');
        } catch(Exception e) {
            System.assert( e.getMessage().contains('Invalid characters in key') );
        }

        // Unexpected end of JSON on Key
        try {
            uJson j = new uJson('{"test');
        } catch(Exception e) {
            System.assert( e.getMessage().contains('Unexpected end of JSON') );
        }
        
        // Unexpected end of JSON on String value
        try {
            uJson j = new uJson('{"test": "true');
        } catch(Exception e) {
            System.assert( e.getMessage().contains('Unexpected end of JSON') );
        }
        
        // Unexpected end of JSON on value
        try {
            uJson j = new uJson('{"a":[0,1');
        } catch(Exception e) {
            System.assert( e.getMessage().contains('Unexpected end of JSON') );
        }
        
        // Error processing array
        try {
            uJson j = new uJson('{"a":[0,1 }');
        } catch(Exception e) {
            System.assert( e.getMessage().contains('Invalid JSON while parsing array') );
        }
        
        // Error processing array
        try {
            uJson j = new uJson('{"a":');
        } catch(Exception e) {
            System.assert( e.getMessage().contains('Unexpected end of JSON while parsing value') );
        }
    }
  
}