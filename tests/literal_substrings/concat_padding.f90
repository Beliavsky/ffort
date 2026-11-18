program p
implicit none
integer::i
character(7)::s
i=2
s='<'//'abc'(i:i)//'>'
if(s/='<b>    ') error stop 1
print *, 'padding' 
end program
