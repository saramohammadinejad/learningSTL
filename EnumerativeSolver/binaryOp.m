    classdef binaryOp < handle
        properties             
            name            
            excludesL
            excludesR
            commutes
            temporal
        end        
        methods
            function opObj = binaryOp(name, excludesL, excludesR, commutes, temporal)
                opObj.name = name;                
                opObj.excludesL = excludesL;
                opObj.excludesR = excludesR;
                opObj.commutes = commutes;
                opObj.temporal = temporal;
            end            
            function c = isCommuter(bOp)
                c = bOp.commutes;
            end      
            function a = arity(bOp)
                a = 2;
            end                  
            function f = isExcludedL(bOp, opName)
                f = any(ismember(bOp.excludesL, opName));
            end
            function f = isExcludedR(bOp, opName)
                f = any(ismember(bOp.excludesR, opName));
            end
            function f = isTemporal(bOp)
                f = bOp.temporal;
            end
        end
end

