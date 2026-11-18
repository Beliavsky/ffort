program p
implicit none
integer::i
character(20)::ch
i=-2;ch='2'
if (i < 0) ch = "-" // trim(ch)
if(ch/='-2') error stop 1
print *, 'negative line' 
end program
