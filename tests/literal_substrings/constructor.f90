program p
implicit none
integer::i
character(2)::s(3)
i=2
s=[character(2)::'abcdef'(i:3),'012'(i:i),'xyz'(:1)]
if(any(s/=[character(2)::'bc','1','x'])) error stop 1
print *, 'constructor' 
end program
