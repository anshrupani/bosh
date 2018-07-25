package brats_test

import (
	"io/ioutil"
	"os"
	"path/filepath"

	bratsutils "github.com/cloudfoundry/bosh-release-acceptance-tests/brats-utils"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/ginkgo/extensions/table"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gexec"

	"fmt"
	"time"
)

var _ = Describe("Blobstore", func() {
	Context("SSL", func() {
		testDeployment := func(allowHttp bool, schema string, errorCode int) {
			By(fmt.Sprintf("specifying blobstore.allow_http (%v) and agent.env.bosh.blobstores (%v)", allowHttp, schema))
			bratsutils.StartInnerBosh(
				fmt.Sprintf("-o %s", bratsutils.AssetPath("op-blobstore-https.yml")),
				fmt.Sprintf("-v allow_http=%t", allowHttp),
				fmt.Sprintf("-v agent_blobstore_endpoint=%s://%s:25250", schema, bratsutils.InnerDirectorIP()),
			)

			bratsutils.UploadRelease("https://bosh.io/d/github.com/cloudfoundry/syslog-release?v=11")
			bratsutils.UploadStemcell(candidateWardenLinuxStemcellPath)

			session := bratsutils.Bosh("-n", "deploy", bratsutils.AssetPath("syslog-manifest.yml"),
				"-d", "syslog-deployment",
				"-v", fmt.Sprintf("stemcell-os=%s", bratsutils.StemcellOS()),
			)
			Eventually(session, 10*time.Minute).Should(gexec.Exit(errorCode))
		}

		DescribeTable("with allow_http true", testDeployment,
			Entry("allows http connections", true, "http", 0),
			Entry("allows https connections", true, "https", 0),
		)

		DescribeTable("with allow_http false", testDeployment,
			Entry("does not allow http connections", false, "http", 1),
			Entry("allows https connections", false, "https", 0),
		)
	})

	Context("Access Log", func() {
		var tempBlobstoreDir string

		BeforeEach(func() {
			bratsutils.StartInnerBosh()

			var err error
			tempBlobstoreDir, err = ioutil.TempDir(os.TempDir(), "blobstore_access")
			Expect(err).ToNot(HaveOccurred())

			bratsutils.UploadRelease(boshRelease)

			session := bratsutils.OuterBosh("-d", bratsutils.InnerBoshDirectorName(), "scp", fmt.Sprintf("bosh:%s", BLOBSTORE_ACCESS_LOG), tempBlobstoreDir)
			Eventually(session, time.Minute).Should(gexec.Exit(0))
		})

		It("Should log in correct format", func() {
			accessContent, err := ioutil.ReadFile(filepath.Join(tempBlobstoreDir, "blobstore_access.log"))
			Expect(err).ToNot(HaveOccurred())
			Expect(string(accessContent)).To(ContainSubstring("CEF:0|CloudFoundry|BOSH|-|blobstore_api|"))
		})
	})
})
