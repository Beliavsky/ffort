program p
implicit none
print *, verify('FORTRAN','AO'), verify('FORTRAN','AO',.true.)
print *, verify('FORTRAN','C++'), verify('FORTRAN','FORTRAN')
print *, verify('','abc'), verify('abc',''), verify('abc','',.true.)
print *, verify(' a ',' '), verify(' a ',' ',.true.), verify('ABC','abc')
print *, verify(kind=8,back=.true.,set='A',string='ABA'), kind(verify('x','x',kind=8))
print *, verify('ab','b',kind=8), verify(set='b',string='ab')
end program
