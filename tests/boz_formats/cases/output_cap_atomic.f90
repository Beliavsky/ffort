program p
implicit none
integer::a(65)
a=1
write(*,'(a)',advance='no')'SAFE'
print '(*(b0.1024))',a
end program
