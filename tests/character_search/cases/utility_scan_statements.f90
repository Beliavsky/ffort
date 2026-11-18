program p
implicit none
character(100)::text
character(4)::delimiters=" ,-."
integer::i1,i2
text='1-5 8 11 .. 15'
i1=1
i2 = scan( text(i1:), delimiters )
print *, i2
i1=2
print *, scan( text(i1:i1), delimiters ) > 0

end program
