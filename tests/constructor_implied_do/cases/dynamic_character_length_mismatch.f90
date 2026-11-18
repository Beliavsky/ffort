program main
implicit none
integer::i
character(3)::x(3),a(3)
print '(a)',"before"
x=["a  ","bb ","c  "]
a=[(trim(x(i)),i=1,3)]
end program
