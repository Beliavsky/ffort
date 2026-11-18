program p
implicit none
print '(a)', '<'//adjustl('  abc ')//'>'
print '(a)', '<'//adjustr(' abc  ')//'>'
print '(a)', '<'//adjustl('   ')//'>'
print '(a)', '<'//adjustr('')//'>'
print '(a)', '<'//adjustl(achar(9)//' a ')//'>'
end program
