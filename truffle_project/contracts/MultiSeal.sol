pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

//多人印章合约
contract MultiSeal {
    string hash;        //签约文件摘要(hash) 
    address promoter;   //签章发起人账户地址   
    string code;        //签章文件编号
    uint number;        //签约账户个数
    address[] accounts; //签章账户列表 
    mapping(address => RecordInfo) recordMap;  //签章记录
    SignStatus status;

    //签章状态枚举    
    enum SignStatus {
        START,    //发起签章
        SIGNING,  //签章中
        FINISH   //完成签章
    }

    //签章记录结构体
    struct RecordInfo {
        bool isSigned;   //是否签章
        string hash;     //签章文件摘要(hash)
        string datetime; //签章时间戳
    }

    //构造函数（_address：签章发起人账户地址，_code:签章文件编号 _number:签章人数 _accounts：签章账户数组）
    constructor(address _address, string _code, uint _number, address[] memory _accounts) public {
        code = _code;
        number = _number;
        accounts = _accounts;
        promoter = _address;
        status = SignStatus.START;
    }

    //初始化签章账户状态
    function initSigner() public {
        for (uint index = 0; index < accounts.length; ++index) {
            address _address = accounts[index];
            recordMap[_address] = RecordInfo(false, "0", "0");
        }
    }

    //获取准备签章账户地址
    function getSigner() view public returns (address){
        for (uint index = 0; index < accounts.length; ++index) {
            address _address = accounts[index];
            RecordInfo storage recordInfo = recordMap[_address];
            if (!recordInfo.isSigned) {
                return _address;
            }
        }
        return address(0);
    }

    //获取签章文件编号
    function getCode() view public returns (string) {
        return code;
    }

    //签章（_address：签章账户地址 _hash:签章文件摘要 _datetime：签章时间）
    function sign(address _address, string _hash, string _datetime) public {
        require(status == SignStatus.START || status == SignStatus.SIGNING, "status is error");

        RecordInfo storage recordInfo = recordMap[_address];
        recordInfo.isSigned = true;
        recordInfo.hash = _hash;
        recordInfo.datetime = _datetime;
        status = SignStatus.SIGNING;

        //设置签章状态
        if (isFinish()) {
            hash = _hash;
            status = SignStatus.FINISH;
        }
    }

    //获取当前签章状态
    function signStatus() view public returns (SignStatus){
        return status;
    }

    //是否完成签章
    //返回值 true:完成签章 false:未完成签章
    function isFinish() view internal returns (bool) {
        for (uint index = 0; index < accounts.length; ++index) {
            address _address = accounts[index];
            RecordInfo storage recordInfo = recordMap[_address];
            if (!recordInfo.isSigned) {
                return false;
            }
        }
        return true;
    }

    //获取多人签约信息
    //返回值：（签章文件摘要，签章发起人，签章文件编号，签章人数，签章账户数组）
    function multiSingInfo() view public returns (string, address, string, uint, address[] memory) {
        return (hash, promoter, code, number, accounts);
    }

    //根据签章人获取多人签章信息（签章人账户地址）
    //返回值：签章文件编号
    function multiSingInfoFromSigner(address _address) view public returns (string memory) {
        require(_address != address(0));
        for (uint index = 0; index < accounts.length; ++index) {
            if (_address == accounts[index]) {
                return code;
            }
        }
    }
}    