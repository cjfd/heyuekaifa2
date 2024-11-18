pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

//印章合约
contract Seal {
    bool isUsed; //印章状态

    //印章信息
    struct SealInfo {
        //①姓名
        //②身份证
        //③印章数据
        //④创建印章时间戳
    }

    //签章记录
    struct RecordInfo {
        string code;
        string datetime;
    }

    SealInfo public sealInfo;

    //签章记录（key：签章文档hash值，value：签章记录）
    mapping(string => RecordInfo) recordMap;
    string[] keys;

    //构造函数
    constructor(string _name, string _cardId, string _data, string _datetime) public {
        //①用户姓名
        //②用户身份ID
        //③用户数据
        //④时间戳
        isUsed = true;
    }
    //设置印章状态
    function setIsUsed(bool _status) public {
        isUsed = _status;
    }

    //获取印章状态
    function getIsUsed() view public returns (bool) {
        return isUsed;
    }

    //获取印章数据
    function getSealData() view public returns (string) {
        return sealInfo.data;
    }

    //获取账户信息
    function getSealInfo() view public returns (string, string, string) {
        return (sealInfo.name, sealInfo.cardId, sealInfo.datetime);
    }

    //签章
    function signature(string _hash, string _code, string _datetime) public {
        recordMap[_hash] = RecordInfo(_code, _datetime);
        keys.push(_hash);
    }

    //获取签章记录
    function getRecord(string _hash) view public returns (string, string) {
        RecordInfo memory recordInfo = recordMap[_hash];
        return (recordInfo.code, recordInfo.datetime);
    }

    //获取所有签章摘要(hash)
    function getAllHash() view public returns (string[] memory) {
        return keys;
    }

}