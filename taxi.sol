pragma solidity 0.5.1;
contract TaxiContract{
    
    uint32 ownedCarId;
    address manager;
    address payable public carDealer_address;
    uint contract_balance = address(this).balance;
    uint participation_Fee;
    uint8 number_of_participation;
    uint fixExpenses;
    uint expensesDate;
    uint contract_pay_date;

    struct Participant{

        uint participant_account_balance;
        bool participant_status;
        bool driver_approve;  // checks if it has voted before
        bool car_approve;     // checks if it has voted before
        bool car_repurchase_approve;    // checks if it has voted before
    }

    struct taxi_driver {
        uint salary;
        uint driver_balance;
        address payable driver_address;
        uint approval_count;
        uint8 hasDriver;   // 0 -> There is no proposed driver.  1 -> There is a proposed driver.  2-> There is a working driver.
        uint payDate;
    }

    struct ProposedCar {
        uint32 CarId;
        uint price;
        uint offer_valid_time;
        uint approval_state;
        uint hasCar;   // 0-> There is no proposed car.  1-> There is a proposed car.  2-> There is a purchased car..
    }


    struct ProposedRepurchaseCar{
        uint32 CarId;
        uint price;
        uint offer_valid_time;
        uint approval_state;
        uint hasOffer;   // 0-> There is no offer.    1-> There is a offer.
    }

    mapping (address=>Participant) public participants;
    address[] public participants_address_list;
    taxi_driver taxiDriver;
    ProposedCar proposed_car;
    ProposedRepurchaseCar proposed_repurchase_car;

    constructor() public{
        manager = msg.sender;
        participation_Fee = 10 ether;  // 10 ether
        number_of_participation = 0;
        fixExpenses = 10 ether;

    }

    function join() public payable{

        require(msg.value == participation_Fee,"Participant fee is 10 ether. Please send 10 ether.");
        require(number_of_participation < 9 ," Participants are limited to 9 people.");
        require(participants[msg.sender].participant_status == false, "Each participant can participate only once.");
        require(msg.sender != manager, "Manager can not participate in this contract.");

        participants_address_list.push(msg.sender);
        address participation_address = msg.sender;
        participants[participation_address].participant_status =true;
        number_of_participation +=1;
        contract_balance = contract_balance + msg.value;
    }

    function setCarDealer(address payable car_Dealar)public onlyManager{
        carDealer_address = car_Dealar;
    }

    function carProposeToBusiness (uint32 _car_id, uint _price, uint _offer_valid_time) public onlyCarDealar{

        require (proposed_car.hasCar != 2, "There is a purchased car. ");

        proposed_car.CarId = _car_id;
        proposed_car.price = _price * 1 ether;
        proposed_car.offer_valid_time = now +  _offer_valid_time * 1 days;
        proposed_car.approval_state = 0;
        uint j;
            for (j =0; j < number_of_participation; j++){
                participants[participants_address_list[j]].car_approve = false; // it can vote again for the new propose.
            }

        proposed_car.hasCar = 1;  // 1 means: There is a offer for purchase the car.
    }

    function approvePurchaseCar () public onlyParticipant {

        require(proposed_car.hasCar !=2, "There is a purchased car. ");
        require(proposed_car.hasCar !=0, "There is no proposed car.");
        require(participants[msg.sender].car_approve == false , "Each participant can vote only once.");
        proposed_car.approval_state += 1;
        participants[msg.sender].car_approve = true;
    }

    function purchaseCar() public onlyManager {

        require(proposed_car.hasCar != 2, " There is an approved car.");
        require(proposed_car.hasCar != 0, " There is no proposed car.");
        require(contract_balance > proposed_car.price, " There is not enough money.");
        require(proposed_car.offer_valid_time >= now, "The offer has expired. ");
        require(proposed_car.approval_state > number_of_participation /2, "More than half of the participations must approve the driver.");

        ownedCarId = proposed_car.CarId;
        carDealer_address.transfer(proposed_car.price);
        proposed_car.hasCar =2;
        contract_balance -= proposed_car.price;
    }

    function repurchaseCarPropose(uint32 _car_id, uint _price, uint _offer_valid_time) public onlyCarDealar{
        require (proposed_car.hasCar == 2, "There is no car to sell." );
        require(ownedCarId == _car_id, "This is not a purchased car.");

        proposed_repurchase_car.CarId = _car_id;
        proposed_repurchase_car.price =_price * 1 ether;
        proposed_repurchase_car.offer_valid_time = now + _offer_valid_time * 1 days;
        proposed_repurchase_car.approval_state = 0;
        proposed_repurchase_car.hasOffer = 1; // 1 means: There is a offer for repurchase the car.
        uint k;
            for(k=0; k< number_of_participation; k++){
                participants[participants_address_list[k]].car_repurchase_approve = false;  //it can vote again for the new propose.
            }
    }

    function approveSellProposal () public onlyParticipant {
        require (proposed_car.hasCar == 2, "There is no car to sell." );
        require (proposed_repurchase_car.hasOffer == 1, " There is no proposed car for sale.");
        require(participants[msg.sender].car_repurchase_approve == false,"Each participant can vote only once.");

        proposed_repurchase_car.approval_state += 1 ;
        participants[msg.sender].car_repurchase_approve = true;

    }

    function repurchaseCar() public payable onlyCarDealar{

        require (proposed_car.hasCar == 2, "There is no car to sell." );
        require(proposed_repurchase_car.hasOffer == 1, " There is no sales offer for the car.");
        require(proposed_repurchase_car.offer_valid_time >= now, "The offer has expired. ");
        require(proposed_repurchase_car.price == msg.value, "Please send as much ether as the offer.");
        require(proposed_repurchase_car.approval_state > number_of_participation /2, "More than half of the participants must approve the purchase. ");

        contract_balance += msg.value;
        proposed_car.hasCar = 0;
        proposed_repurchase_car.hasOffer = 0;
        // delete ownedCarId;
        ownedCarId = 0;

    }

    function proposeDriver(address payable _taxiDriverAddress, uint _salary) public onlyManager {

        require(taxiDriver.hasDriver != 2, "There is a working taxi driver.");

        taxiDriver.driver_address = _taxiDriverAddress;
        taxiDriver.salary = _salary * 1 ether;
        taxiDriver.approval_count = 0;
        taxiDriver.hasDriver = 1; // 1 means: There is a proposed driver.
        uint i;
            for(i =0; i < number_of_participation; i++){
                participants[participants_address_list[i]].driver_approve = false; // it can vote again for the new propose.
            }
    }

    function approveDriver() public onlyParticipant {
        require(taxiDriver.hasDriver != 2, "There is a working taxi driver.");
        require(taxiDriver.hasDriver != 0, "There is no proposed driver.");
        require(participants[msg.sender].driver_approve == false, "Each participant can vote only once.");
        taxiDriver.approval_count += 1;
        participants[msg.sender].driver_approve = true;
    }

    function setDriver() public onlyManager {
        require(taxiDriver.hasDriver != 2, "There is a working taxi driver.");
        require(taxiDriver.hasDriver != 0, "There is no proposed driver.");
        require(taxiDriver.approval_count > number_of_participation / 2, "More than half of the participants must approve the driver.");

        taxiDriver.hasDriver = 2;
        taxiDriver.payDate = 0;

    }

    function fireDriver() public onlyManager {
        require(taxiDriver.hasDriver == 2, "There is no working driver.");
        taxiDriver.hasDriver = 0;
        taxiDriver.driver_balance += taxiDriver.salary;
        contract_balance -= taxiDriver.salary;
        taxiDriver.driver_address.transfer(taxiDriver.driver_balance);
        taxiDriver.driver_balance = 0;
        taxiDriver.payDate = now;
        delete taxiDriver.driver_address;
    }

    function payTaxiCharge () public payable {
        contract_balance = contract_balance + msg.value;
    }

    function releaseSalary () public onlyManager {

        require(taxiDriver.payDate + 30 * 1 days < now, " This function can be called only once in 1 months. ");
        require(contract_balance > taxiDriver.salary, "There is not enough money in the contract");
        require(taxiDriver.hasDriver == 2, "There is no working driver.");
        taxiDriver.driver_balance += taxiDriver.salary;
        contract_balance -= taxiDriver.salary;
        taxiDriver.payDate = now;
    }

    function getSalary () public onlyTaxiDriver {

        require(taxiDriver.driver_balance > 0, "There is no money in the account.");
        taxiDriver.driver_address.transfer(taxiDriver.driver_balance);
        taxiDriver.driver_balance = 0;
    }

    function payCarExpenses () public onlyManager{

        require(expensesDate + 180 days < now, "This function can be called only once in 6 months.");
        require(contract_balance > fixExpenses, "There is not enough money in the contract");
        require (proposed_car.hasCar == 2, "There is no car." );
        expensesDate =now;
        carDealer_address.transfer(fixExpenses);
        contract_balance -= fixExpenses;
    }

    function payDividend () public onlyManager{

        require(contract_pay_date + 180 days < now, "This function can be called only once in 6 months.");
        uint profit;
        profit = contract_balance;

        if (expensesDate + 180 days < now && proposed_car.hasCar == 2 ){
            require(profit > fixExpenses, "There is no profit to be distributed after paying the expenses.");
            profit -= fixExpenses;
        }

        if (taxiDriver.payDate + 30 days < now && taxiDriver.hasDriver == 2){
            require(profit > taxiDriver.salary, "There is no profit to be distributed after paying the expenses.");
            profit -= taxiDriver.salary;
        }

        require(profit > 0, "There is no profit to be distributed after paying the expenses.");
        profit = profit / number_of_participation;
        uint i;
        for(i=0; i < number_of_participation; i++){

             participants[participants_address_list[i]].participant_account_balance += profit;
             contract_balance -= profit;
        }
        contract_pay_date = now;
    }

    function getDividend () public onlyParticipant {

        require(participants[msg.sender].participant_account_balance > 0, "There is no money in the account." );
        msg.sender.transfer(participants[msg.sender].participant_account_balance);
        participants[msg.sender].participant_account_balance = 0;
    }

    function () external{  //Fallback
        revert();
    }

    modifier onlyManager(){
        require(msg.sender == manager," Only Manager can call this function.");
        _;
    }

    modifier onlyParticipant(){
        require(participants[msg.sender].participant_status  == true, "Only Participants can call this function");
        _;
    }

    modifier onlyCarDealar(){
        require(msg.sender == carDealer_address, "Only CarDealar can calls this function");
        _;
    }

    modifier onlyTaxiDriver(){
        require(msg.sender == taxiDriver.driver_address, "Only Taxi Driver can calls this function");
        _;
    }
}
