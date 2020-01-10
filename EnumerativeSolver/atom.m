classdef atom < handle    
    properties 
        varName
        operator
        constant        
    end
    
    methods
        function atomObj = atom(varName, operator, constant)
            atomObj.varName = varName;
            atomObj.operator = operator;
            atomObj.constant = constant;
        end        
        function str = toString(atomObj)
            str = sprintf('%s[t] %s %s', atomObj.varName, ...
                                      atomObj.operator, ...
                                      atomObj.constant);
        end        
        function formula = toSTL(atomObj)
            formula = STL_Formula(atomObj.toString(), atomObj.toString());
        end            
    end
end