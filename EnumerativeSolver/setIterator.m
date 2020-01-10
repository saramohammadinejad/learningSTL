classdef setIterator < handle
   properties
      iterator
      theSetHandle      
   end
   methods
       function it = setIterator(aSet)
           it.theSetHandle = aSet;
           if (isempty(aSet))
               it.iterator = 0;
           else
               it.iterator = 1;
           end            
       end
       function reset(it)
           if (isempty(it.theSetHandle))
               it.iterator = 0;
           else
               it.iterator = 1;
           end
       end              
       function b = inRange(it)
           b = ((it.iterator > 0) && (it.iterator<=length(it.theSetHandle)));
       end
       function insert(it,element)
           if (it.iterator == 0)
               it.iterator = 1;
           end
           it.theSetHandle{end+1} = element;
       end
       function remove(it)
           it.theSetHandle(:,it.iterator) = [];
       end
       function f = deref(it)
           try
               f = it.theSetHandle{it.iterator};
           catch
               fprintf('warning: invalid iterator index!\n');              
           end
       end
       function increment(it)           
           it.iterator = it.iterator + 1;                      
       end
       function f = next(it)
           f = it.deref();
           it.increment();
       end
       function resetTo(it, anotherSetIterator)
           it.iterator = anotherSetIterator.iterator;
       end
   end
end