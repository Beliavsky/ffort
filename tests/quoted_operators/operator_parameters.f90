program p
implicit none
character(*),parameter::plus='+',minus='-',n='.not.',custom='.yes.'
if(plus//minus/='+-'.or.n/='.not.'.or.custom/='.yes.') error stop 1
print *, 'parameters' 
end program
