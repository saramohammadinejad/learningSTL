function ret = existsFormula(id)    
    global BreachGlobOpt
    if (ischar(id))
        ret = isKey(BreachGlobOpt.STLDB,id);
    else
        ret = false;
    end
end        
