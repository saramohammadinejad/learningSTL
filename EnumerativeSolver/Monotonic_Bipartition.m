classdef Monotonic_Bipartition < handle
    properties
        lowerbound
        upperbound
        boundry_points
        formula
        params
        paramranges
        numparams
        num_steps
        uncertainty
        BreachTrace
        validity_domain
        MonoDirection
    end
    
    methods
        function this = Monotonic_Bipartition (formula,paramranges,num_steps,uncertainty,BreachTrace,MonoDirection)
            
            this.params = fieldnames(get_params(formula));
            this.numparams = length(this.params);
            this.lowerbound=paramranges(1:this.numparams);
            this.upperbound=paramranges(this.numparams+1:2*this.numparams);
            this.num_steps = num_steps;
            this.uncertainty = uncertainty;
            this.BreachTrace = BreachTrace;
            this.formula = formula;
            this.MonoDirection=MonoDirection;
            this.boundry_points= [];
            this.validity_domain=[];
            m=num_steps;
            bin=BinaraySearch (this.formula,this.lowerbound,this.upperbound,this.BreachTrace, this.uncertainty);
            this.boundry_points = [bin.result_binsearch_point,this.boundry_points];
            if this.numparams == 1
                return
            end
            this.validity_domain=[bin.validity_domain, this.validity_domain];
            this.boundry_points=this.Monotonic_Bipartition_rec (this.lowerbound,bin.result_binsearch_point,this.upperbound,m);
            
        end
        
        function[lowerbound_points,upperbound_points] = Produce_lowerbounds (this, startpoint,result_binsearch_point,endpoint)
            lowerbound_points = [];
            upperbound_points = [];
            n=this.numparams;
            for i = 1:(n-1)
                indexes = nchoosek([1:n],i); 
                for j=1:size (indexes,1)
                    point = result_binsearch_point;
                    for k= 1: size (indexes,2)
                        if this.MonoDirection(indexes(j,k))==1
                            point(indexes(j,k)) = endpoint(indexes(j,k));
                        elseif this.MonoDirection(indexes(j,k))==0
                            point(indexes(j,k)) = startpoint(indexes(j,k));
                        end
                    end
                    lowerbound_points = [point,lowerbound_points];    
                end  
            end
            lowerbound_points = reshape(lowerbound_points,n,(2^n-2))';
            for i = 1 : size(lowerbound_points,1)
                for j = 1:size(lowerbound_points,2) 
                    if this.MonoDirection (j) == 1
                        if lowerbound_points(i,j)== result_binsearch_point(j)
                            upperbound_points (i,j)= startpoint(j);
                        elseif lowerbound_points(i,j)== endpoint(j)
                            upperbound_points (i,j)= result_binsearch_point(j);
                        end
                    elseif this.MonoDirection (j) == 0
                        if lowerbound_points(i,j)== result_binsearch_point(j)
                            upperbound_points (i,j)= endpoint(j);
                        elseif lowerbound_points(i,j)== startpoint(j)
                            upperbound_points (i,j)= result_binsearch_point(j);
                        end 
                        
                        
                    end
                end
            end
        end
        
        function boundray_points = Monotonic_Bipartition_rec(this,lowerbound_point,binpoint,upperbound_point,m)
            n=this.numparams;
            [lowerbound_points,upperbound_points]=this.Produce_lowerbounds (lowerbound_point,binpoint,upperbound_point);
            if m==0
                boundray_points = this.boundry_points;
                return
            else
                for j = 1:(2^n-2)
                    bin = BinaraySearch (this.formula,lowerbound_points(j,:),upperbound_points(j,:),this.BreachTrace, this.uncertainty);
                    this.boundry_points = [bin.result_binsearch_point, this.boundry_points];
                    this.validity_domain=[bin.validity_domain, this.validity_domain];
                    boundray_points = Monotonic_Bipartition_rec(this,lowerbound_points(j,:),bin.result_binsearch_point,upperbound_points(j,:),m-1);
                end
            end
                
        end
        
    end
    
end