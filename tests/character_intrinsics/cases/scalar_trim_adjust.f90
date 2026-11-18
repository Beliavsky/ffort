program p
implicit none
print *, len_trim(''),len_trim('   '),len_trim(' a  '),len_trim(string=' a  ',kind=8)
print *, kind(len_trim('x')),kind(len_trim('x',8))
print '(a)',adjustl('  abc '),adjustr(' abc  '),adjustl(string='  '),adjustr(string='')
print *, len(adjustl('  abc ')),len(adjustr(' abc  '))
end program
