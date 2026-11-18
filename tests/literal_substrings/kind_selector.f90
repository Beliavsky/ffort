program p
integer,parameter::k=len('12345678'(1:4))
integer(kind=k)::i
i=9
if(kind(i)/=4) error stop 1
print *, 'kind selector'
end program
