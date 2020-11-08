/*
    This exercise has been updated to use Solidity version 0.5
    Breaking changes from 0.4 to 0.5 can be found here: 
    https://solidity.readthedocs.io/en/v0.5.0/050-breaking-changes.html
*/

pragma solidity ^0.5.0;

contract SupplyChain {

  address private owner;
  uint private skuCount;
  mapping (uint => Item) private items;

  enum State { ForSale, Sold, Shipped, Received }

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  event LogForSale(uint sku);
  event LogSold(uint sku);
  event LogShipped(uint sku);
  event LogReceived(uint sku);

  modifier onlyOwner {
    require(msg.sender == owner, "Unauthorized");
    _;
  }

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address, "Unauthorized"); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price, "Nonsufficient Funds"); 
    _;
  }

  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier forSale(uint _sku) {
    Item storage item = items[_sku];
    require(item.seller != address(0) && item.state == State.ForSale, "Invalid Item State - not for sale");
    _;
  }

  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold, "Invalid Item State - expected Sold");
    _;
  }

  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped, "Invalid Item State - expected Shipped");
    _;
  }
  
  modifier received(uint _sku) {
    require(items[_sku].state == State.Received, "Invalid Item State - expected Received");
    _;
  }

  constructor() public {
    owner = msg.sender;
    skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns(bool){
    emit LogForSale(skuCount);
    items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    skuCount = skuCount + 1;
    return true;
  }

  function buyItem(uint sku) public payable forSale(sku) paidEnough(items[sku].price) checkValue(sku) {
    Item storage item = items[sku];
    item.state = State.Sold;
    item.buyer = msg.sender;
    (bool success, ) = item.seller.call.value(item.price)("");
    require(success, "Transfer failed");
    emit LogSold(sku);
  }

  function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller) {
    items[sku].state = State.Shipped;
    emit LogShipped(sku);
  }

  function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer) {
    items[sku].state = State.Received;
    emit LogReceived(sku);
  }

  /* We have these functions completed so we can run tests, just ignore it :) */
  function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }

}
