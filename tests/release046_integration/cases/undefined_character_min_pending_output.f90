program p
implicit none
character(2)::a,b
b='zz'
write(*,'(a,t2,a)',advance='no')'ABCD','x'
print '(a)',min(a,b)
end program
