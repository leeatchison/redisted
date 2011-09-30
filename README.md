Redisted
========

Redisted provides higher level model functionality for redis databases. It is not intended as an ActiveRecord
plugin. If you want to use ActiveRecord, use a SQL database or something like Mongoid. Redisted is designed
to provide model symatics but customized and optimized for redis data store.

Do not expect ActiveRecord compatibility, but expect ActiveRecord-like capabilities highly taylored and customized to
take best advantage of Redis.

Installing
==========



Configuring
===========

Creating Models
===============
A basic Redisted model looks like this:

    class MyModel < Redisted::Base
    end

Within the model, you specify fields, indices, relations, scopes, and additional model functionality, just like
you do with ActiveRecord models.

Instantiating Instances
=======================
Creating an instance is as simple as new or create:

    # Creating an instance in memory only
    obj=MyModel.new

    # Creating and persisting an instance to Redis:
    obj=MyModel.create
    puts obj.id # <<<---An 'id' is created when it is persisted to Redis.

    # Creating in memory, then later saving to Redis:
    obj=MyModel.new
    ...
    obj.save
    puts obj.id # <<<---The 'id' was created at time of 'save'

Fields
======
Redis is a basic key/value store that is inheritantly schema-less. Redisted continues this by allowing the dynamic
specification fields without having to create a static schema that must be migrated. Simply adding a field
to the model specification makes it available. No database migration is necessary.

To specify a field in Redisted, you use the field command. This command looks like this:

    field :field_name,type: :field_type

Field type can be one of :string, :integer, or :datetime. Here is an example class with fields defined:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :size, type: :integer
      field :created, type: :datetime
    end

Instances of a Redisted model are stored in a single Redis hash. The name of the key is based on the name of the
model and the ID associated with that model. For example, a MyModel instance (such as above), with an ID value
of 1234 would be stored in a hash under the key:

    mymodel:1234

Individual fields within the hash would correspond to each field within the model. Each field is stored in Redis as
a string, and Redisted deals with converting that string to/from the desired field types, defined above.

Destroying an instance of a Redisted model is as simple as deleting the corresponding Redis key.

Reading/Writing Fields
----------------------
Reading/writing a value to a field is as simple as using the included accessors:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :size, type: :integer
      field :created, type: :datetime
    end

    obj=MyModel.create
    obj.name="My Name"
    puts "Name: #{obj.name}"

If the object is persisted to Redis (using 'create' to make the object or a previous call to 'save', and therefore it has an 'id'), then
by default reading/writing attributes read and write the value directly from Redis. For instance, using the above model:

    obj=MyModel.create
    obj.name="MyName" # Issues Redis call: HSET my_model[123] name "MyName"
    puts "Name: #{obj.name}" # Issues Redis call: HGET my_model[123] name

To save round trip latency to Redis when you are making several changes to an instance, you can cache the changes:

    obj=MyModel.create
    obj.cache do
        obj.name="MyName"
        obj.size=123
        obj.size=obj.size+222
    end # Issues Redis call: HMSET my_model[123] name "MyName" size "345"

Or:

    obj=MyModel.create
    obj.cache
    obj.name="MyName"
    obj.size=123
    obj.size=obj.size+222
    obj.save # Issues Redis call: HMSET my_model[123] name "MyName" size "345"

When an object has not yet been persisted to disk (has no 'id'), this is the normal behavior:

    obj=MyModel.new # <<<---Caching is on until the first save...
    obj.name="MyName"
    obj.size=123
    obj.size=obj.size+222
    obj.save # Issues Redis call: HMSET my_model[123] name "MyName" size "345"
    obj.name="MyName2" # <<<---This now reverts to normal, non-caching functionality and issues immediately: HSET my_model[123] name "MyName2"

You can change the default persisting strategy for an entire class within the class definition:

    class MyModel < Redisted::Base
      always_cache_until_save # <<<--- Tells Redisted to always cache each change until 'save' is called
      field :name, type: :string
      field :size, type: :integer
      field :created, type: :datetime
    end
    obj=MyModel.create
    obj.cache
    obj.name="MyName"
    obj.size=123
    obj.size=obj.size+222
    obj.save # Issues Redis call: HMSET my_model[123] name "MyName" size "345"

For reading, the value is first checked to see if it has already been cached (by a previous read or write). If not, then
it will be read directly from Redis:

    obj=MyModel.find(123) #<<<--- Assumes an object with this 'id' was previously created
    puts obj.name # Issues Redis call: HGET my_model[123] name
    puts obj.name # Reads from cache...no Redis call made
    obj.name="MyName" # Issues redis call: HSET my_model[123] name "MyName"
    puts obj.name # Reads from cache...no Redis call made

You can flush the cache and force a reread from Redis at any time:

    obj=MyModel.find(123) #<<<--- Assumes an object with this 'id' was previously created
    puts obj.name # Issues Redis call: HGET my_model[123] name
    puts obj.name # Reads from cache...no Redis call made
    obj.name="MyName" # Issues redis call: HSET my_model[123] name "MyName"
    puts obj.name # Reads from cache...no Redis call made
    obj.flush
    puts obj.name # Issues Redis call: HGET my_model[123] name

Cache Pre-Read
--------------
You can force an object to always pre-read all values into the cache at object create by specifying an object in the
model class:

    class MyModel < Redisted::Base
      cache_on_first_get # <<<--- Tells Redisted to always cache when an object is instantiated from Redis
      field :name, type: :string
      field :size, type: :integer
      field :created, type: :datetime
    end
    obj=MyModel.find(123) # Issues Redisc all: HMGET my_model[123] name size created
    puts obj.name # Reads from cache...no Redis call made

You can specify which keys you want to pre-read in a couple different ways:

    pre_cache_all # Pre-read all keys
    pre_cache_all keys: :all # Same as above
    pre_cache_all keys: [:name,:size] # Only pre-read name &size, and not created (in this example)
    pre_cache_all except: [:content] # Only pre-read name &size, and not created (in this example)

You can specify when the pre-read occurs individually:

    pre_cache_all when: :create        # Load the cache when the object is first created (via find, or any other way)
    pre_cache_all when: :first_read    # Defer loading the cache until the first pre-cachable field is read from the object, then load the entire cache

List of Fields
--------------
You can get a list of available fields from either a class or an object as follows:

    obj=MyModel.new
    field_list=MyModel.fields
    or:
    field_list=obj.fields

This will return a hash with each key representing a field, and the value being a list of options provided during the
field create. For instance:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :size, type: :integer, default: 0
      field :created, type: :datetime
    end
    field_list=MyModel.fields

This will produce the following hash:

    {
        name: {
            type: :string
        },
        size: {
            type: :integer,
            default: 0
        },
        created: {
            type: :datetime
        },
    }

Note that there may be other values in field-specific hash, such as default option values, etc., and the list may
change over time. You should only assume that values you specifically add to the field definition appear in this
hash, and that other values may or may not be present.

Validations
===========



Basic Find
==========

<talk about .find(id) and .find([id,id])>

Indices
=======


Scopes
======


References (aka Relationships)
==============================
Redisted is great for creating models that are "in between" other non-Redisted models, such as ActiveRecord models or
Mongoid models. Redis in general is great for creating integrated maps of values, such as object references. In fact,
Redisted was created out of a need for a very fast way of assocating large number of 'tags' to a large number of
'messages' stored in Mongoid very efficiently.

As such, the relation mechanims in Redisted are optimized for creating not only references to other Redisted models,
but to models of other backend stores, such as ActiveRecord and Mongoid.

LEELEE: TODO


Filter, Search, Sort
====================


