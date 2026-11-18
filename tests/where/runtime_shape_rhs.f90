program p
implicit none
integer::n=2,a(3)=0,b(3)=1
where([.false.,.false.,.false.]) a=b(1:n)
end program
