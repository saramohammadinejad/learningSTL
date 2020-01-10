classdef unaryOp < handle
        properties             
            name            
            excludes            
            temporal        
        end        
        methods            
            function this = unaryOp(name, excludes, temporal)
                this.name = name;                
                this.excludes = excludes;
                this.temporal = temporal;
            end            
            function a = arity(this) %#ok<*MANU>
                a = 1;
            end            
            function f = isExcluded(this, opName)
                f = any(ismember(this.excludes, opName));
            end
            function f = isTemporal(this)
                f = this.temporal;
            end
        end
end

