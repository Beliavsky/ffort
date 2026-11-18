program p
implicit none
print '(a)', '<'//repeat('a ',3)//'>'
print '(a)', '<'//repeat(ncopies=2_8,string=' b')//'>'
print '(a)', '<'//repeat('x',ncopies=0)//'>'
print '(a)', '<'//repeat('',9)//'>'
print '(a)', '<'//repeat(repeat('q ',2),2)//'!'//'>' 
end program
