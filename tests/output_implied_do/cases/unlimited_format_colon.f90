program main
implicit none
integer::i
character(4)::a(3)
a=["ab  "," c  ","    "]
print '(*( "[",a,"]":,1x))', (trim(a(i)),i=1,3)
end program
