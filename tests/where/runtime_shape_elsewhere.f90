program p
implicit none
integer::n=2,a(3)=0
where(a==0)
a=1
elsewhere(a(1:n)==0)
a=2
end where
end program
