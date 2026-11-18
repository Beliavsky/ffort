program p
implicit none
character(5)::a(4)
a=[character(5)::'+','-','.not.','.yes.']
if(a(1)/='+'.or.a(2)/='-'.or.a(3)/='.not.'.or.a(4)/='.yes.') error stop 1
print *, 'constructor' 
end program
