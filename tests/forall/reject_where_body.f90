program p
implicit none
integer::i,a(2)
forall(i=1:2)
where(a>0) a=i
end forall
end program
