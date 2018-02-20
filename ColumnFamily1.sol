pragma solidity ^0.4.0;

library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string _a, string _b) public pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string _a, string _b) public pure returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string _haystack, string _needle) public pure returns (int)
    {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
    		return -1;
    	else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;									
    	else
    	{
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++)
    		{
    			if (h[i] == n[0]) // found the first char of b
    			{
    				subindex = 1;
    				while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
    				{
    					subindex++;
    				}	
    				if(subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}	
    }
}

contract ColumnFamily1 {

    struct Right {
        string column;
        string value;
        int256 version;
    }

    address public owner;
    string public columnFamilyName;
    //number of live versions of a cell to keep
    uint8 keepVersions;
    //Maps a rowkey to all columns
    mapping (string => Right[]) data;
    //Maps only the latest value of a single sell
    mapping (string => mapping(string => string)) latestData;
    
    function ColumnFamily1(string name, uint8 versions) public {
        owner = msg.sender;
        columnFamilyName = name;
        keepVersions = versions;
    }

    function writeCell(string rk, string column, string value, int256 version) public returns (int code) {
        
        Right[] memory r = data[rk];
        //If r is empty simply add
        if (r.length == 0){
            data[rk].push(Right({column: column, value: value, version: version}));
            latestData[rk][column] = value;
            return 10;
        }
        int256 highestVersion = int256(-1);
        int256 highestIndex = int256(-1);
        //figure out what the max value is for real
        uint256 lowestIndex = uint256(10000);
        int256 lowestVersion = int256(10000);
        uint256 matchedCount = uint256(0);
        for (uint256 i=0; i< r.length; i++){
            if (StringUtils.equal(r[i].column, column)){
                matchedCount = matchedCount + 1;
                if (r[i].version > highestVersion){
                    highestIndex = int256(i);
                    highestVersion = r[i].version;
                }
                if (r[i].version < lowestVersion){
                    lowestIndex = i;
                    lowestVersion = r[i].version;
                }
            }
        }
        //if not found add it
        if (matchedCount == uint256(0)){
            latestData[rk][column] = value;
            data[rk].push(Right({column: column, value: value, version: version}));
            return 20;
        }
        log0(bytes32(version));
        log0(bytes32(highestVersion));
        if (version > highestVersion){
            if (matchedCount >= keepVersions) {
                latestData[rk][column] = value;
                data[rk][lowestIndex] = Right({column: column, value: value, version: version});
                return 30;
            } else {
                latestData[rk][column] = value;
                data[rk].push(Right({column: column, value: value, version: version}));
                return 40;
            }
        }
        return 50;
    }
    
    function get(string rk, string column) public constant returns (string value) {
        return latestData[rk][column];
    }
    
}
