program p
implicit none
integer::s,d
s=1;d=0
write(*,*)"must-not-leak",eoshift([1,2],s,dim=d)
end program
