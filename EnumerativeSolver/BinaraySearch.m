classdef BinaraySearch < handle
    
    properties
        sat
        unsat
        numparams
        uncertainty
        result_binsearch_point
        validity_domain
   
    end
    
    methods
        function this = BinaraySearch (formula,lowerbound,upperbound,breachtrace, uncertainty)
           
    
            params = fieldnames(get_params(formula));
            this.numparams = length(params);
            this.uncertainty = uncertainty;
            this.validity_domain = [];
           
            
        
            
     
            
            formula = set_params(formula,params, upperbound);
            f_upperbound = formula;
            get_params(f_upperbound);
            breachtrace.CheckSpec(f_upperbound);
            sat_upperbound=min(breachtrace.CheckSpec(f_upperbound));
            
            
            formula = set_params(formula,params,lowerbound);
            f_lowerbound = formula;
            get_params(f_lowerbound);
            breachtrace.CheckSpec(f_lowerbound);
            sat_lowerbound=min(breachtrace.CheckSpec(f_lowerbound));
            
           if (sat_upperbound >= sat_lowerbound)
                this.sat = upperbound;
                this.unsat = lowerbound;
           else
                this.sat = lowerbound;
                this.unsat = upperbound;
           end
           this.validity_domain = [this.sat,this.validity_domain];

           while (sqrt(sum(abs(this.sat-this.unsat)))>uncertainty)
                    
                middlepoint=(this.sat + this.unsat)/2;
                formula = set_params(formula,params, middlepoint);
                f_middlepoint = formula;
                get_params(f_middlepoint);
                breachtrace.CheckSpec(f_middlepoint);
                sat_middlepoint = min(breachtrace.CheckSpec(f_middlepoint));
                if (sat_middlepoint<0)
                    this.unsat =  middlepoint;
                else
                    this.sat =  middlepoint;
                end
                this.validity_domain = [this.sat,this.validity_domain];
      
                
           end
           this.result_binsearch_point= (this.unsat + this.sat)/2;
                
           
        end
    end
end