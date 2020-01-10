classdef YAP < handle % YAP = yet another params data structure
    % 
    properties
        params 
        numTotalTraces
        numParamSamples
        signatureIds
        numSignatureTraces
        signatureTraces
        timeRange
        signatures
        params_map
        discrepancyTolerance
    end
    methods
        function this = YAP(signals, numTotalTraces, options)    
            this.setDefaultIndistinguishabilityOptions(options); 
            this.numTotalTraces = numTotalTraces;
            this.params = struct;
            this.signatures = containers.Map();%Object that maps values to unique keys
            this.params_map = containers.Map();
            this.signatureIds = ...
                    sort(randperm(this.numTotalTraces, this.numSignatureTraces)); %p = randperm(n,k) returns a row vector containing k unique integers selected randomly from 1 to n inclusive.           
            [this.signatureTraces, this.timeRange] = makeBreachTraceSystem(signals);                                    
            for i=1:length(signals)                
                signalParams = signals{i}.params;                
                for j=1:length(signalParams)
                    param = signalParams{j};
                    pRange = signals{i}.range;
                    this.params.(param).range = pRange;
                    
                    this.params.(param).samples = ... % samples from param ranges
                        pRange(1) + (pRange(2) - pRange(1))*rand(1,this.numParamSamples);
                    
                   
                end
            end
        end
        function addParam(this, paramName, paramRange)
            if (isfield(this.params, paramName))
                return;
            end
            this.params.(paramName).range = paramRange;
            lb = repmat(paramRange(1), 1, this.numParamSamples); 
            ub = repmat(paramRange(2), 1, this.numParamSamples);          
            this.params.(paramName).samples = lb + (ub-lb).*rand(1, this.numParamSamples);            
        end
        function addTimeParams(this, formula)
            timeParams = get_params(formula);
            fns = fieldnames(timeParams);
            % extract only the interval params
            timeParams = regexp(fns, 'tau_\d', 'match');
            timeParams = sort(unique([timeParams{:}]));
            for j=1:length(timeParams)
                this.addParam(timeParams{j}, this.timeRange);                
            end            
        end            
        function nom = getIthNominalValue(this, paramsList, i)
            nom = [];
            paramsList = this.getParamsList(paramsList);
            for j=1:length(paramsList)
                param = paramsList{j};
                if (~isfield(this.params, param))
                    error('Cannot find parameter %s in YAP.\n', param);
                end
                nom = [nom, this.params.(param).samples(i)]; %#ok<*AGROW>
            end           
        end
        function paramsList = getParamsList(this, paramsList)
            if (ischar(paramsList)) 
                paramsList = { paramsList };
            end
            if (isstruct(paramsList))
                paramsList = fieldnames(paramsList);
            end
            if (~iscell(paramsList))
                error('Cannot recognize argument paramsList.\n');
            end
        end            
        function ranges = getParamRanges(this, paramsList)
            ranges = [];
            paramsList = this.getParamsList(paramsList);
            for j=1:length(paramsList)
                param = paramsList{j};
                if (~isfield(this.params, param))
                    error('Cannot find parameter %s in YAP.\n', param);
                end
                ranges = [ranges; this.params.(param).range];
            end            
        end 
        function this = addTrace(this, traceNum, trace)
            if (any(ismember(traceNum,this.signatureIds)))
                this.signatureTraces.AddTrace(trace);
            end
        end
        function setDefaultIndistinguishabilityOptions(this, options)
            if (~exist('options','var'))
                options = struct;
            end                
            if (~isfield(options, 'numParamSamples'))
                this.numParamSamples = 5;
            else
                this.numParamSamples = options.numParamSamples;
            end
            if (~isfield(options, 'numSignatureTraces'))
                this.numSignatureTraces = 10;
            else
                this.numSignatureTraces = options.numSignatureTraces;
            end            
            if (~isfield(options, 'discrepancyTolerance'))
                this.discrepancyTolerance = 1e-3;
            else
                this.discrepancyTolerance = options.discrepancyTolerance;
            end
        end
        function flag = isNew(this, formula)            
            %  trace_number X parameter-space-point                        
            fparams = sort(fieldnames(get_params(formula)));
            paramString = [fparams{:}];
            flag = true;
            existingFormulas = keys(this.signatures);
            signature = this.getSignature (formula);
            for j=1:numel(existingFormulas)
                existingFormula = existingFormulas{j};
                existingParams = this.params_map(existingFormula);
                if (string(paramString) == string(existingParams))
                    existingSignature = this.signatures(existingFormula);
                    if (norm(existingSignature-signature,2) < this.discrepancyTolerance)
                        flag = false;
                        %fprintf('Found formula %s same as existing formula %s.\n', ...
                        %disp(formula), existingFormula);
                        return;
                    end           
                end
            end
            this.signatures(disp(formula))=signature;
            this.params_map(disp(formula))=paramString;
        end
        function signature = getSignature(this, formula)
            signature = zeros(this.signatureTraces.CountTraces(), ...
                              this.numParamSamples);            
            for i=1:this.numParamSamples
                fparams = fieldnames(get_params(formula));
                fparamsValues = this.getIthNominalValue(fparams, i);
                formulaI = set_params(formula, fparams, fparamsValues);
                signature(:,i) = this.signatureTraces.CheckSpec(formulaI);            
            end
        end
    end
end
















