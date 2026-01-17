# Daemon

This project is a test/example of distributing an executable, AND a supplementary library to
accompany the executable in the same project. The example mimics a daemon/server executable with a
library containing the protocol for use by both the executable and by clients.

A separate project *could* be used to factor out the common protocol library, where clients use the
library, and the executable is linked to the library. Although that may be *more* canonical, it's
often a pain to maintain a complete separate project for something so coupled, like protocols.