program p
implicit none
character(*),parameter::s=repeat('a ',3)
integer,parameter::n=len(repeat('xy',4_8))
character(n),parameter::t=repeat('xy',4)
print *,len(s),len(t),n,kind(s),len(repeat('',0))
print '(a)', '<'//s//'>'
print '(a)', '<'//t//'>' 
end program
