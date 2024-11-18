pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

import "./Seal.sol";
import "./MultiSeal.sol";

//主合约
contract ElectronicSeal {
    address owner;  //合约拥有者
    uint8 counter;  //印章账户计数器

    //key为签章账户地址
    mapping(address => Seal) sealMap;  //个人签章表

    //key为签章账户地址
    mapping(address => bool) signerMap; //签章账户表

    //key为签章发起人账户地址
    mapping(address => MultiSeal) multiSealMap; //多人签章表

    //key为签章文件编号
    mapping(string => MultiSeal) multiSealHistory; //多人签章历史记录表
    string[] codes;

    //key为签章发起人账户地址
    mapping(address => bool) promoterMap; //签章发起人表

    //个人签章事件
    event AddSealAccountEvent(address, string, string, string);
    event CancelSealAccountEvent(address);
    event SealSignature(address, string, string, string);

    //构造函数
    constructor() public {
        owner = msg.sender;
        counter = 0;
    }

    //判断合约调用者是否为合约拥有者
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call");
        _;
    }

    //判断合约调用者是否为签章发起人
    modifier onlyPromoter() {
        require(promoterMap[msg.sender] == true, "Only Promoter can call");
        _;
    }

    //判断合约调用者是否为签约账户
    modifier onlySigner() {
        require(signerMap[msg.sender] == true, "Only Signer can call");
        _;
    }

    //判断合约调用者是否签章发起人或签章账户
    modifier onlyPromoterOrSinger() {
        require(promoterMap[msg.sender] == true || signerMap[msg.sender] == true, "Only Signer or Promoter can call");
        _;
    }

    ////////////////////////单人签名/////////////////////////////

    //添加签章账户（_account：签章账户地址，_name:签章账户姓名，_cardID:签章账户身份证号码，_data:印章数据,_datetime:申请印章时间）
    function addSealAccount(address _account, string _name, string _cardId, string _data, string _datetime) public onlyOwner {
        Seal seal = new Seal(_name, _cardId, _data, _datetime);
        sealMap[_account] = seal;
        signerMap[_account] = true;
        counter++; //整数溢出漏洞
        emit AddSealAccountEvent(_account, _name, _cardId, _datetime);
    }

    //添加账户签章信息（_account：签章账户地址，_hash:签章文件摘要,_datatime:签章时间）
    function sealSignature(address _account, string _hash, string _code, string _datetime) public onlyOwner {
        require(_account != address(0));
        Seal seal = sealMap[_account];
        if (seal.getIsUsed()) {
            seal.signature(_hash, _code, _datetime);
        }
        emit SealSignature(_account, _hash, _code, _datetime); //代码逻辑漏洞
    }

    //查看账户信息（_account：签章账户地址）
    function getSealAccount(address _account) view public returns (string, string, string) {
        require(_account != address(0));
        Seal seal = sealMap[_account];
        return seal.getSealInfo();
    }

    //查看账户签章信息（_account：签章账户地址，_hash:签章文件摘要）
    function querySignature(address _account, string _hash) view public returns (string, string) {
        require(_account != address(0));
        Seal seal = sealMap[_account];
        return seal.getRecord(_hash);
    }

    //查看账户签章hash值（_account：签章账户地址）
    function queryAllHash(address _account) view public returns (string[] memory) {
        require(_account != address(0));
        Seal seal = sealMap[_account];
        return seal.getAllHash();
    }

    //注销印章账户（_account：签章账户地址）
    function cancelSealAccount(address _account) public onlyOwner {
        require(_account != address(0));
        Seal seal = sealMap[_account];
        signerMap[_account] = false;
        seal.setIsUsed(false);
        counter--; //整数溢出漏洞
        emit CancelSealAccountEvent(_account);
    }

    //查看印章数据（_account：签章账户地址）
    function getSealData(address _account) view public onlyOwner returns (string) {
        require(_account != address(0));
        Seal seal = sealMap[_account];
        return seal.getSealData();
    }

    //查看注册印章账户数量
    function getSealAccountCounter() view public onlyOwner returns (uint) {
        return counter;
    }

    /////////////////////多人签名//////////////////////

    //签章发起人注册（_address:签章发起人账户地址）
    function addPromoter(address _address) public onlyOwner {
        require(_address != address(0));
        promoterMap[_address] = true;
    }

    //是否签章发起人（_address:签章发起人账户地址）
    function isPromoter(address _address) public view onlyOwner returns (bool) {
        require(_address != address(0));
        if (promoterMap[_address]) {
            return true;
        }

        return false;
    }

    //签章发起人发起多人签章(_code:签章文件编号 _number:签章人数 _accounts:签章账户数组)
    function startMultiSign(string _code, uint _number, address[] memory _accounts) public onlyPromoter {
        require(address(multiSealMap[msg.sender]) == address(0));
        require(!isExistMultiCode(_code), "code is exist.");

        MultiSeal multiSeal = new MultiSeal(msg.sender, _code, _number, _accounts);
        multiSeal.initSigner();
        multiSealMap[msg.sender] = multiSeal;
    }

    //@dev 多人签章
    //@param _address 签章人账户地址
    //@param _hash 签章文件摘要
    //@param _datatime 签章时间戳
    function doMultiSign(address _address, string _hash, string _datetime) public onlyPromoter {
        //①判断传入的签章人账户地址不能为空
        //②获取多人签章合约对象实例
        //③获取当前等待签章账户地址
        //④判断合约调用者是否为等待签章人账户地址
        //⑤进行签章
    }

    //完成多人签章
    function finishMultiSign() public onlyPromoter {
        MultiSeal multiSeal = multiSealMap[msg.sender];
        require(multiSeal.signStatus() == MultiSeal.SignStatus.FINISH, "status is signing.");

        //存储多人签章记录
        string memory code = multiSeal.getCode();
        multiSealHistory[code] = multiSeal;
        codes.push(code);

        //清除表数据
        multiSealMap[msg.sender] = MultiSeal(address(0));
    }

    //@dev 获取多人签章信息
    //@param _code 签章文件编号
    //@return (签章文件摘要、多人签章发起人账户地址、签章文件编号、签章人数、签章账户地址列表)
    function getMultiSingInfo(string _code) public view onlyPromoterOrSinger returns (string, address, string, uint, address[] memory) {
        //①获取多人签章合约对象实例
        //②返回多人签章信息
    }

    //获取所有多人签名文件编号
    function getCodes() view public onlyOwner() returns (string[] memory){
        return codes;
    }

    //签章账户查看签章记录（多人）
    //返回值：签章账户所参与多人签章的所有文件编号
    function getSingInfoFromSigner() view public onlySigner returns (string[] memory) {
        string[] memory _codes = new string[](codes.length);
        uint num = 0;

        //获取签约文件编号
        for (uint index = 0; index < codes.length; index++) {
            string memory code = codes[index];
            MultiSeal multiSeal = multiSealHistory[code];
            if (keccak256(bytes(code)) == keccak256(bytes(multiSeal.multiSingInfoFromSigner(msg.sender)))) {
                _codes[index] = multiSeal.getCode();
                num++;
            }
        }

        //整理签约文件编号数组（去空值）
        string[] memory codeArr = new string[](num);
        uint sn = 0;
        for (uint ind = 0; ind < _codes.length; ++ind) {
            if (bytes(_codes[ind]).length != 0) {
                codeArr[sn] = _codes[ind];
                sn++;
            }
        }

        return codeArr;
    }

    //@dev 判断多人签名文件编号是否存在
    //@param _code 签章文件编号
    //@return bool true:存在 false：不存在
    function isExistMultiCode(string _code) view internal returns (bool) {
        //①遍历所有多人签章文件编号并与传入签章文件编号参数进行比较
        //②返回不存在
    }
}
