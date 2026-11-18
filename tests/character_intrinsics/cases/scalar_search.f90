program p
implicit none
print *, index('banana','ana'),index('banana','ana',.true.)
print *, index('banana','z'),index('banana',''),index('banana','',back=.true.)
print *, index('',''),index('','',.true.),index('','a'),index('a','ab')
print *, index(substring='a',string='banana',back=.true.),index('a  ',' ')
print *, index('banana','ana',kind=8),index(kind=8,substring='ana',back=.true.,string='banana')
print *, kind(index('abc','b')),kind(index('abc','b',.false.,8))
end program
