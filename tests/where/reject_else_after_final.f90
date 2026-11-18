program p
implicit none
integer::a(2)=0
where(a==0)
a=1
elsewhere
a=2
elsewhere(a>0)
a=3
end where
end program
