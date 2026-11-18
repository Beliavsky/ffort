program p
implicit none
integer::a(2)=0
where(a==0)
call random_number(a)
end where
end program
