program p
implicit none
integer::i
i=1
if('+'(i:i)/='+'.or.'-'(:)/='-'.or.'.not.'(2:4)/='not') error stop 1
print *, 'substring' 
end program
