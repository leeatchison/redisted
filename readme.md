PLEASE NOTE
===========

This is still ***UNDER DEVELOPMENT*** and not yet ready for prime-time. Feel free to fool around with it, file bug
reports (via GitHub), and make suggestions. It is a work in progress. However, I do hope to have a fully
flushed out implementation as soon as possible.


Redisted
========

Redisted provides higher level model functionality for redis databases. It is not intended as an ActiveRecord
plugin. If you want to use ActiveRecord, use a SQL database or something like Mongoid. Redisted is designed
to provide model symatics but customized and optimized for redis data store.

Do not expect ActiveRecord compatibility, but expect ActiveRecord-like capabilities highly taylored and customized to
take best advantage of Redis.

Installing
==========

TODO

Configuring
===========

TODO

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
    end # Issues Redis call: HMSET my_model[112334] name "MyName" size "345"

Or:

    obj=MyModel.create
    obj.cache
    obj.name="MyName"
    obj.size=123
    obj.size=obj.size+222
    obj.save # Issues Redis call: HMSET my_model[112334] name "MyName" size "345"

You can also pass in a hash to the create call:

    obj=MyModel.create({name: "MyName", size: 123}) # Issue Redis call:HMSETmy_model[112334] name "MyName" size "123"

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

Basic Find
==========

The easiest way to locate and open an object from Redis is to use find. Find expects one parameter, the 'id' of the object
you wish to open:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :size, type: :integer, default: 0
      field :created, type: :datetime
    end
    obj=MyModel.find(1963)
    puts obj.id # Returns 1963
    puts obj.name # Returns the name of the object with 1963
    ...

You can also pass an array of 'id' values, and find will return an array of objects:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :size, type: :integer, default: 0
      field :created, type: :datetime
    end
    objs=MyModel.find([1963,1982,1994])
    puts objs[0].id # Returns 1963
    puts objs[0].name # Returns the name of object with id 1963
    puts objs[1].id # Returns 1982
    puts objs[1].name # Returns the name of object with id 1982
    puts objs[2].id # Returns 1994
    puts objs[2].name # Returns the name of object with id 1994

Delete and Destroy
==================

You can delete an object by calling the delete method on an instance:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :size, type: :integer, default: 0
    end
    obj=MyModel.create({name: "test", size: 15}) # Redis call: HMSET my_model:1122 name "test" size "15"
    obj.delete # Redis call: DEL my_model:1122

Destroy does the same thing, but you can specify standard callbacks to be run (see callbacks, below).

Indices
=======

Indices in Redisted are different than in other similar packages. Indices are *required* in order to filter, sort, or
determine uniqueness of items in a model. The entire filter/sort UI is dependent on the creation of indices.

Unique Index
------------

A unique index is an index that specifies a field or group of fields who's value must be unique across all items
of the given model. It is specified as such:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer

      index :name, unique: true
    end

In this example, all instances of MyModel must maintain a unique "name" field. This information is persisted in
Redis using a *SET*. The set is stored in a key specific to the model and the index. The redis key for the "name"
unique index in Redis for the model above may look like this:

    SET: my_model[name]

Every time a new MyModel instance is persisted, a member is added to this SET. Everytime it is deleted, the corresponding
member is deleted. Each time the value of "name" changes, the old member is removed and a new one is added. All of this
occurs atomically using optimistic locking on this set key and the model hash key.

If you try and create/persiste an instance of the model where the "name"is not unique, an exception will be raised.
If you are performing saves one change at a time (the default), the check is made at the time when the assignment
is made to the name field. If you are using cached writes, it is performed at the time of the save.

The above syntax creates a unique index named "name" that is unique across the single field "name". You can specify
unique indices in other ways as well:

    index :ti, unique: :test_int
      # Creates an index named "ti" that is unique across the field "test_int"
    index :idxkey, unique: [:test_int,:name]
      # Creates an index named "idxkey" that is unique across "test_int"/"name" field pair (the pair of values must be
      # unique).

The index name must be unique across all indexes for a given model.


Filter/Sort Index
-----------------
A filter/sort index is an index that can be used to return a filtered set of items and/or sorted in a particular way.

Here is a simple example:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer

      index :odd, includes: ->(elem){(elem.test_int%2)!=0}
      index :even, includes: ->(elem){(elem.test_int%2)==0}
    end

This model creates two indexes, one that contains a list of all model instances where test_int is odd, the other
contains a list of all model instances where test_int is even.

With the above specification, you can then use the following commands:

    MyModel.by_odd.all    # Returns an array of all instances of MyModel where test_int is odd...
    MyModel.by_even.all   # Returns an array of all instances of MyModel where test_int is even...

The order of the returned results is not specified. Using this example, the indexes are maintained in SORTED
SETS (ZADD/ZREM/etc.). The name of the keys are:

    my_model[odd]
    my_model[even]

Each key will contain a member referring to the 'id' value of the instance that is contained in this index. For
this example, the sort "score" is set to 1 (more on this later). Each time an instance is created or modified, the
lambda function for the index specified in the model declation is executed. If the function returns true, then an
entry for this instance is added to the index. If it is false, any existing entry for this instance is removed. When
an instance is deleted, it's entry (if it exists) is deleted.

You may specify a sort index as follows:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer

      index :asc, order: ->(elem){elem.test_int},fields: :test_int
    end

This creates an index named asc, that is implemented as a SORTED SET with the following key:

    my_model[asc]

In this case, *all* instances of MyModel have their 'id' value inserted as a member in this set, and their sort
"weight" is set to the value returned by the lambda function (order:).

With the above specification, when you use the index like so:

    MyModel.by_asc.all

You will get an array of all objects in the model, sorted in ascending order by "test_int".

Note that the lambda function can perform any calculation and return any result. For a reverse sort, you can simply
put a minus sign in front of the equation.

While the lambda can contain any information, the value of the Redis "weight" (as returned by the method) is only
recalculated if one of the fields specified in the fields: parameter (which may be an array of fields) has changed
values. Thus, it's important to include in this array all fields that are used for the order calculation.

An index may be both a filter and a sort index, by combining the syntax:

    index :sortedodd,includes: ->(elem){(elem.test_int%2)!=0}, order: ->(elem){elem.test_int}, fields: :test_int

In this case, the entry will only be included in the index if the "includes" lambda returns true, and when inserted
it will be given a sort "weight" of the value returned by the "order" lambda. The "weight"is only recalculated if
the "test_int" field changes value.

When using indexes, you can mix and match them in a single call. For instance, using all of the above indexes, you can
perform the following lookups:

    MyModel.by_odd.all
      # Returns an array of all instances of MyModel where test_int is odd...
    MyModel.by_asc.all
      # Returns all instances of MyModel sorted by test_int.
    MyModel.by_odd.by_asc.all
      # Returns all instances of MyModel where test_int is odd, sorted by test_int.
    MyModel.by_sortedodd.all
      # Same as above: Returns all instances of MyModel where test_int is odd, sorted by test_int.

Match Index
-----------

The above indexes provide a very high performant way of doing static filters. It works well when the specific
queries are known in advance. This is because the indexes contain a specific set of static keys, and membership in the
index is determined at the time the model is saved.

When possible, these indexes are efficient and powerful. However, it's not always possible to do a query this way.

That is why there are match indexes. A match index is used when a value needed for the query is not known ahead
of time (at model save time). Here is the declaration of a match index:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :test_int, type: :string
      field :provider, type: :string

      index :provider, match: ->(elem){(elem.provider)}
    end

With an index like this, you can perform queries such as the following:

    a=MyModel.by_provider("cable").all
    or:
    a=MyModel.by_provider("satellite").all

At model creation/save time, several SORTED SETS are created for this index, one for each unique value returned
by the various objects when they call the "match" lambda. For instance, in the above example, if the only values
that "provider" is ever set to are "cable", "satellite", or "overair", then the following keys are generated:

    my_model[provider]:cable
    my_model[provider]:satellite
    my_model[provider]:overair

Each key is a SORTED SET who's members are the 'id' values of objects where the "match" lambda returns the specified
value. So, when you call 'by_provider("cable")', you include the 'my_model[provider]:cable' key in the query.

The individual keys are created the first time a value is returned by the "match" function (i.e., when the first
member is inserted). If a query is run for a value that does not yet have a key, such as the following:

    MyModel.by_provider("xyzzy").all

then the query will act as if it returns an empty set (which it is).



Incomplete Queries
------------------
Just like in ActiveRecord, you can store intermediate results of a nested query, and use the results later. For
instance, each of these does the exact same thing:

In line:

    MyModel.by_odd.by_asc.all

Stored in a variable each step:

    a=MyModel.by_odd
    a=a.by_asc
    a.all

Storing the query and processing it later:

    a=MyModel.by_odd.by_asc
    ...
    a.all

Starting with a blank query:

    a=MyModel.scoped
    a=a.by_odd
    a=a.by_asc
    a.all

The query is performed by calling ZINTERSTORE on each of the sorted sets. However, these ZINTERSTORE calls are not
performed until the ".all" is executed. This way you can setup a query in a controller, for instance, and it only
will execute if the view issues the ".all" on it.

Besides ".all", you can also use ".each":

    MyModel.by_odd.by_asc.each do |model|
      # 'model' contains each instance that matches the query
    end


Updating An Index
-----------------
Given how indexes are created and handled, it is recommended that you do *not* modify the lambda function of an
index after the index has been created and populated. Doing so is inviting problems, since the index is not
regenerated when the function changes.

If you must change the meaning of an index, we recommend you actually create a new index and begin using that, then
obsolete the old one when it is not used any more. Using scopes (discussed below) rather than raw index can help
make this easier.

If you *must* change the lambda function, then you should rebuild the indexes for the model from scratch immediately
after changing the function.

From the command line:

    rake redisted:recalculate_all

Programatically (one model):

    MyModel.recalculate

Programatically (all models):

    Redisted::recalculate_all

For each index, this will cause the old index to be destroyed, and a new one to be regenerated. Depending on the
number and complexity of the indexes, and the number of objects in the model, this could take some time. Since
indexes in redisted are *required* to do queries, rather than simply providing performance enhancements, access
to the query functionality of the model is offline while this reindex occurs, and hence should be performed during
a maintenance window.

TODO: Need a way to specify to *pause* query calls rather than failing them during an index recalcuate.

TODO: Note that this entire recalculate interfact does not yet exist.

Index Uniqueness
----------------

The names of the indexes must be unique across all indexes for this model. This goes for unique, filter/sort,
and 'match' indexes.

Scopes
======

Using scopes, you can specify a complex query and refer to it using a simple identifer. For example, combining
much of the above:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer
      field :provider, type: :string

      index :odd, includes: ->(elem){(elem.test_int%2)!=0}
      index :even, includes: ->(elem){(elem.test_int%2)==0}
      index :provider, match: ->(elem){(elem.provider)}
      index :asc, order: ->(elem){elem.test_int},fields: :test_int

      scope :sorted_odd, ->{by_odd.by_asc}
      scope :odd_providers, ->(name){by_odd.provider(name)}
    end

Then, you can use them in queries:

    MyModel.sorted_odd.all
    MyModel.odd_providers.all

Validations
===========

Standard ActiveModel validations work with Redisted. Such as:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer
      field :provider, type: :string

      validates_length_of :name, :minumum=>5
      validates_length_of :provider, :maximum=>20
    end

TODO:Note that "validates_uniqueness_of" is not yet supported...

References (aka Relationships)
==============================
Redisted is great for creating models that are "in between" other non-Redisted models, such as ActiveRecord models or
Mongoid models. Redis in general is great for creating integrated maps of values, such as object references. In fact,
Redisted was created out of a need for a very fast way of assocating large number of 'tags' to a large number of
'messages' stored in Mongoid very efficiently.

As such, the relation mechanims in Redisted are optimized for creating not only references to other Redisted models,
but to models of other backend stores, such as ActiveRecord and Mongoid.

There are only two reference types, references_one and references_many. Here is an example:

    class MyModel < Redisted::Base
      field :name, type: :string
      field :test_int, type: :integer
      field :provider, type: :string

      references_one :user
      references_many :message

      references_one :another_class, as: :aclass
      references_many :another_class, as: :theclasses
    end

The "references_one" creates a reference to a single object of another model. The model does not have to be
a redisted model (but it can be), it can be ActiveRecord, Mongoid, anything that accepts a ".find(id)" call.

With a references_one field, you can:

    u=ARUser.create
    mm=MyModel.create

    mm.user=u
    or:
    mm.user_id=u.id

    u=mm.user # Returns an instance of ARUser
    u=mm.user.xxx # Call method 'xxx' on the instance of ARUser

With a refererences_many field, you can:

    m1=ARMessage.create
    m2=ARMessage.create
    mm=MyModel.create

    mm.message << m1
    mm.message << m2

    mm.message[0] # Returns an instance of ARMessage (m1)
    mm.message[1] # Returns an instance of ARMessage (m2)

This all will work as is, without any changes to the ARUser model. However, you will probably want to install
a destroy callback in ARUser so that the reference is removed if 'u' is destroyed. You can do that using
the following code:

    class ARUser
      Redisted::on_destroy :my_model,:user
    end
    class ARMessage
      Redisted::on_destroy :my_model,:message


Callbacks
=========

Callbacks work the same as ActiveRecord. Redisted supports callbacks on create, update, save, and destroy.
For update and save, the callbacks are called anytime a value is written to Redisted. So, if the model is setup
so that each field update forces a write to Redisted (the default), then these two callbacks are called on each
field update.

Copyright
=========
(c) Lee Atchsion
Permission is given to use this in any system, in whole or in part, without prior permission. No warranty is provided
for any purpose.

If you make improvements or fixes to this code, please submit a pull request to me on GitHub.
