## Real Time Exchange Feature Specs

### Story: User wants to check BTC/USD real time

### Narrative #1

```
As an online user
I want to app to automatically load the latest BTC/USD exchange price for every second
So I can check if my purchasing power as changed in real time.
```

#### Scenarios (Acceptance criteria)

Given the customer has connectivity
When the customer requests to see the latest BTC/USD in real time
Then the app should display the latest BTC/USD
exchange price from remote
and replace the cache with the new exchange price

Given the customer has connectivity
And the app has shown an BTC/USD exchange price
When a second has passed
Then the app should display the latest BTC/USD
exchange price from remote
and replace the cache with the new exchange price

### Narrative #2

```
As an offline customer
I want the app to show the an error message with the last updated value and date
So I can calculate how long has passed since I checked the latest BTC/USD exchange price and its value
```

#### Scenarios (Acceptance criteria)

Given the customer doesn't have connectivity
When the customer requests to see the latest BTC/USD
And the cache is not empty
Then the app should display an error message
with the last updated value and date.

Given the customer doesn't have connectivity
When the customer requests to see the latest BTC/USD
And the cache is empty
Then the app should display an error message.

Given the customer doesn't have connectivity
And the app has shown a BTC/USD exchange price
And the cache is not empty
When a second has passed
Then the app should display an error message
with the last updated value and date.

## Use Cases

### Use Case #1 Remote Load of Exchange of BTC/USD

#### Data:
URL 

#### Primary course: 
- Execute “Remote Load of exchange rate” with the data above.
- System downloads data with the URL above.
- System validates data
- System creates exchange rate value from data.
- System delivers exchange rate value.

#### No connectivity - Error course
System delivers no connectivity.

#### Invalid Data - Error Course
System delivers invalid data.


### Use Case #2 Cache Exchange rate of BTC/USD

#### Data:
Exchange rate

#### Primary course: 
- Execute “Cache Exchange rate” command with data above.
- System deletes stored data.
- System encodes exchange rate value.
- System timestamps new cache data.
- System saves new cache data.
- System delivers success message.

#### Deletion error - Error course 
System delivers error

#### Insertion error - Error course
System delivers error


### Use Case #3 Load Exchange rate of BTC/USD Cache

#### Data:
none

#### Primary course: 
- Execute “Load Exchange rate cache” command.
- System retrieves data from cache.
- System decodes data into exchange rate value.
- System delivers exchange rate value.

#### Retrieval error - Error course 
System delivers error

#### Empty cache - Error Course
System delivers error

