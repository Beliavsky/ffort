program p
implicit none
integer::a(2)=0
where(a==0)
a=1
elsewhere([.true.])
a=2
end where
end program
