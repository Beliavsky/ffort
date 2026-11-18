program p
implicit none
print *, scan('FORTRAN','AO'), scan('FORTRAN','AO',.true.)
print *, scan('FORTRAN','C++'), scan('FORTRAN','FORTRAN')
print *, scan('','abc'), scan('abc',''), scan('abc','',.true.)
print *, scan(' a ',' '), scan(' a ',' ',.true.), scan('ABC','abc')
print *, scan(kind=8,back=.true.,set='A',string='ABA'), kind(scan('x','x',kind=8))
print *, scan('ab','b',kind=8), scan(set='b',string='ab')
end program
