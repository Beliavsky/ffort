program main
implicit none
character(4),parameter::a(2)=['abcd','efgh']
character(len=len(a(2)))::y
y=a(1)
if(y/='abcd') error stop 1
print *, 'PASS'
end program
