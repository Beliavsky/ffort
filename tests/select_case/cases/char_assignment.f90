program p
implicit none
character(len=3)::x
x='abcdef'
print '(a)',x
x='q'
print '(a)',x
print *,x=='q',x<'r',x>='q',trim(x)
x=''
print '(a)',trim(x)
end program p
