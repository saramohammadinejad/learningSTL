classdef formulaIterator < handle
    properties (Constant) 
        notOp = unaryOp('not', {'not', 'always', 'eventually', '=>', ...
                                'until', 'and', 'or'}, 0);
        alwOp = unaryOp('alw', {'always'}, 1);
        evOp = unaryOp('ev', {'eventually'}, 1);%sara 2->1
        andOp = binaryOp('and', {}, {}, 1, 0);
        orOp  = binaryOp('or', {}, {}, 1, 0);
        impliesOp = binaryOp ('=>', {}, {'not'}, 0, 0);
        untilOp = binaryOp('until', {}, {}, 1, 1);
    end
    properties  
        depth                
        formulaDB
        operandIterator
        lhsDepth
        lhsIterator
        rhsIterator
        maxLength 
        operatorIterator
        intervalIterator
        operators
    end
    
    methods        
        function this = formulaIterator(maxLength, signals)  
           this.operators = { this.notOp, this.alwOp, this.evOp, this.andOp, ...
                               this.orOp, this.impliesOp, this.untilOp };
           this.maxLength = maxLength;
           this.depth = 1;
           this.lhsDepth = 1;           
           this.formulaDB{1} = {};            
           if (isempty(signals))
               error('No signal information found. Aborting.\n');
           end
           for i=1:length(signals) % in first call fills formulaDB with 'x[t] > valx' and 'x[t] < valx' and 'y[t] > valy' and 'y[t] < valy' and assigns 0 to parameters valx and valy
               v = signals{i}.name;
               for j=1:length(signals{i}.ops)
                   o = signals{i}.ops{j};
                   for k=1:length(signals{i}.params)
                       c = signals{i}.params{k}; 
                       a = atom(v,o,c);                       
                       formula = a.toSTL();        
                       % some default value for param c, should be 
                       % overwritten by calling functions
                       formula = set_params(formula, c, 0); 
                       this.formulaDB{1}{end+1} = formula;
                   end
               end
           end
           this.operandIterator  = setIterator(this.formulaDB{1});
           this.operatorIterator = setIterator(this.operators);
           this.lhsIterator      = setIterator(this.formulaDB{1});
           this.rhsIterator      = setIterator(this.formulaDB{1});
           this.intervalIterator = 0;
        end
        
        function formula = nextFormula(this)            
            if (this.depth > this.maxLength)
                fprintf('Warning: max formula length exceeded.\n');                
                formula = struct();
                return;
            end
            
            if (this.depth == 1)
                if (this.operandIterator.inRange())
                    formula = this.operandIterator.deref();                                        
                    this.operandIterator.increment();
                    return;
                else
                    this.depth = 2;                                        
                    this.operandIterator.reset();                   
                    formula = this.nextFormula();
                    return;
                end            
            end            
            % if you come here, you have depth at least 2                                    
            if (this.operatorIterator.inRange())
                op = this.operatorIterator.deref();
                if (op.arity()==1)                    
                    if (this.operandIterator.inRange())
                        operand = this.operandIterator.deref();
                        if (op.isExcluded(get_type(operand)))
                            this.operandIterator.increment();
                            formula = this.nextFormula();
                            return;
                        else
                            if (op.isTemporal()>=1)
                                idx = this.getLargestIndexOfIntervalParams(operand);
                                intervalParam = sprintf('tau_%d', idx+1);
                                if (op.isTemporal()<2) || (this.intervalIterator==0)
                                    interval = sprintf('[0,%s]', intervalParam);                                    
                                else
                                    interval = sprintf('[%s,%s]',...
                                    intervalParam, intervalParam);                                    
                                end
                                idStr = sprintf('%s_%s %s', op.name, interval, get_id(operand));
                                formula = STL_Formula(idStr, op.name, interval, operand);
                                formula = set_params(formula, intervalParam, 0);                                
                            else                                
                                idStr = sprintf('%s %s', op.name, get_id(operand));
                                formula = STL_Formula(idStr, op.name, operand);
                            end
                            if (length(this.formulaDB) < this.depth)
                                this.formulaDB{this.depth} = {};
                            end
                            this.formulaDB{this.depth}{end+1} = formula;
                            if (op.isTemporal()==2)
                                this.intervalIterator = 1 - this.intervalIterator;
                            end
                            if (op.isTemporal() < 2) || (this.intervalIterator==0)                                
                                this.operandIterator.increment();
                                return;
                            end
                        end
                    else 
                        this.operatorIterator.increment();
                        this.operandIterator.reset();
                        formula = this.nextFormula();
                        return;
                    end
                else
                    % op.arity() must be 2
                    if (this.depth == 2)
                        % depth=2 formulas can't have binary operators, so
                        % skip
                        this.operatorIterator.increment();
                        formula = this.nextFormula();
                        return;
                    else
                        % depth is > 2
                        if (op.isCommuter() && this.lhsDepth > ceil(this.depth/2))
                           % this means that these combinations
                           % are already seen before, so skip
                           this.operatorIterator.increment();
                           this.lhsIterator.reset();
                           this.rhsIterator.reset();
                           formula = this.nextFormula();
                           return;
                        end
                        if (this.lhsDepth <= this.depth-2)
                            if (this.lhsIterator.inRange())
                                lhs = this.lhsIterator.deref();                               
                                if (op.isExcludedL(get_type(lhs)))
                                    this.lhsIterator.increment();                       
                                    this.rhsIterator.reset();                        
                                    formula = this.nextFormula();
                                    return;
                                end
                                if (this.rhsIterator.inRange())
                                    rhs = this.rhsIterator.deref();
                                    if (op.isExcludedR(get_type(rhs)))
                                        this.rhsIterator.increment();                                        
                                        formula = this.nextFormula();
                                        return;
                                    end
                                    lhsStr = disp(lhs);
                                    rhsStr = disp(rhs);                                
                                    if (strcmp(lhsStr, rhsStr))
                                        this.rhsIterator.increment();
                                        formula = this.nextFormula();
                                        return;
                                    else
                                        if (length(this.formulaDB) < this.depth)
                                           this.formulaDB{this.depth} = {};
                                        end                
                                        
                                        if (op.isTemporal())
                                            idx = max(this.getLargestIndexOfIntervalParams(lhs), ...
                                                      this.getLargestIndexOfIntervalParams(rhs));                                            
                                            intervalParam = sprintf('tau_%d', idx+1);
                                            interval = sprintf('[0,%s]', intervalParam);
                                            idStr = sprintf('%s %s_%s %s', get_id(lhs), op.name, interval, get_id(rhs));
                                            commIdStr = sprintf('%s %s_%s %s', get_id(rhs), op.name, interval, get_id(lhs));
                                            formula = STL_Formula(idStr, op.name, lhs, interval, rhs);
                                            %formula = set_params(formula, intervalBegin, 0);
                                            %formula = set_params(formula, intervalEnd, 0);
                                            formula = set_params(formula, intervalParam, 0);
                                        else
                                            idStr = sprintf('%s %s %s', get_id(lhs), op.name , get_id(rhs));
                                            commIdStr = sprintf('%s %s %s', get_id(rhs), op.name, get_id(lhs));
                                            formula = STL_Formula(idStr, op.name, lhs, rhs);
                                        end                                       
                                        if (op.isCommuter())
                                            if (existsFormula(commIdStr))
                                                 this.rhsIterator.increment();
                                                 formula = this.nextFormula();
                                                 return;                                            
                                            end
                                        end                                        
                                        this.rhsIterator.increment();
                                        this.formulaDB{this.depth}{end+1} = formula;
                                        return;
                                    end
                                else
                                    this.lhsIterator.increment();
                                    this.rhsIterator.reset();
                                    formula = this.nextFormula();
                                    return;
                                end
                            else
                                this.lhsDepth = this.lhsDepth + 1;
                                if (this.lhsDepth <= this.depth-2)
                                    this.lhsIterator = setIterator(this.formulaDB{this.lhsDepth});
                                    this.rhsIterator = setIterator(this.formulaDB{this.depth - this.lhsDepth -1});
                                    this.lhsIterator.reset();
                                    this.rhsIterator.reset();
                                end
                                formula = this.nextFormula();
                                return;
                            end
                        else
                            this.operatorIterator.increment();
                            this.lhsIterator = setIterator(this.formulaDB{1});
                            this.lhsDepth = 1;
                            this.rhsIterator = setIterator(this.formulaDB{this.depth - this.lhsDepth - 1});                            
                            formula = this.nextFormula();
                            return;
                        end
                    end
                end
            else
                this.lhsIterator = setIterator(this.formulaDB{1});
                this.rhsIterator = setIterator(this.formulaDB{this.depth-1});
                this.operatorIterator.reset();
                this.operandIterator = setIterator(this.formulaDB{this.depth});
                this.depth = this.depth + 1;
                this.lhsDepth = 1;
                formula = this.nextFormula();
                return;
            end
        end
        function l = getLargestIndexOfIntervalParams(this,formula) %#ok<INUSL>
            params = get_params(formula);
            fns = fieldnames(params);
            % extract only the interval params
            matches = regexp(fns, 'tau_\d', 'match');            
            matches = [matches{:}];
            if (isempty(matches))
                l = 0;
            else
                l = max(cellfun(@str2num, regexprep(matches, 'tau_(\d)', '$1')));
            end                
        end                        
        function d = getDepth(this)
            d = this.depth;            
        end  
    end
end