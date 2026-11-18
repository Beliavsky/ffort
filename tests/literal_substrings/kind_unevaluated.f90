program p
implicit none
integer::i,j
if(kind('abc'(i:j))/=kind('')) error stop 1
print *, 'kind unevaluated' 
end program
