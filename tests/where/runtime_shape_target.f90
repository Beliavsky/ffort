program p
implicit none
integer::n=2,a(3)=0
where([.true.,.false.]) a(1:n+1)=1
end program
